DROP FUNCTION IF EXISTS get_character_dices(VARCHAR);
CREATE FUNCTION get_character_dices(user_email VARCHAR(254))
RETURNS TABLE (
    id INTEGER,
    dice_1 SMALLINT,
    dice_2 SMALLINT,
    dice_3 SMALLINT
) AS $$
DECLARE
    character_rolls RECORD;
BEGIN
    IF EXISTS (SELECT * FROM characters WHERE "user" = user_email LIMIT 1) THEN RETURN; END IF;
    IF (SELECT count(*) FROM rolls WHERE rolls."user" = user_email LIMIT 5) != 5 THEN
        INSERT INTO rolls (dice_1, dice_2, dice_3, "user") VALUES
            (floor(random() * 6) + 1, floor(random() * 6) + 1, floor(random() * 6) + 1, user_email),
            (floor(random() * 6) + 1, floor(random() * 6) + 1, floor(random() * 6) + 1, user_email),
            (floor(random() * 6) + 1, floor(random() * 6) + 1, floor(random() * 6) + 1, user_email),
            (floor(random() * 6) + 1, floor(random() * 6) + 1, floor(random() * 6) + 1, user_email),
            (floor(random() * 6) + 1, floor(random() * 6) + 1, floor(random() * 6) + 1, user_email);
    END IF;
    RETURN QUERY SELECT rolls.id, rolls.dice_1, rolls.dice_2, rolls.dice_3
        FROM rolls WHERE rolls."user" = user_email
        LIMIT 5;
END;
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS create_character(character varying,character varying, integer, integer, integer, integer, character varying);
CREATE FUNCTION create_character(
    name VARCHAR(20), 
    description VARCHAR,
    strength_roll INTEGER,
    intellect_roll INTEGER,
    dexterity_roll INTEGER,
    constitution_roll INTEGER,
    email VARCHAR(254)
) RETURNS VOID AS $$
        INSERT INTO characters (
            name, 
            description, 
            strength, 
            intellect, 
            dexterity, 
            constitution,
            equipped_defence_item,
            equipped_attack_item,
            "user"
        ) VALUES (
            name, 
            description, 
            (
                SELECT dice_1 + dice_2 + dice_3
                FROM rolls
                WHERE id = strength_roll
                AND "user" = email
            ), 
            (
                SELECT dice_1 + dice_2 + dice_3
                FROM rolls
                WHERE id = intellect_roll
                AND "user" = email
            ), 
            (
                SELECT dice_1 + dice_2 + dice_3
                FROM rolls
                WHERE id = dexterity_roll
                AND "user" = email
            ), 
            (
                SELECT dice_1 + dice_2 + dice_3
                FROM rolls
                WHERE id = constitution_roll
                AND "user" = email
            ), 
            (
                SELECT value FROM defaults WHERE key = 'initial_defence_item'
            ),
            (
                SELECT value FROM defaults WHERE key = 'initial_attack_item'   
            ),
            email
        );
        DELETE FROM rolls WHERE "user" = email;
$$ LANGUAGE 'sql';

DROP FUNCTION IF EXISTS create_room(INTEGER);
CREATE FUNCTION create_room(
    dungeon INTEGER
) RETURNS INTEGER AS $$
    DECLARE
        max_items CONSTANT SMALLINT := 5;
        max_enemies CONSTANT SMALLINT := 2;
        min_enemies CONSTANT SMALLINT := 1;
        room_id INTEGER;
    BEGIN
        INSERT INTO rooms (dungeon, description)
        VALUES (dungeon, (
            SELECT id FROM rooms_descriptions 
            WHERE id != 0 
            ORDER BY random() 
            LIMIT 1
        )) RETURNING id INTO room_id;
        
        INSERT INTO room_items (room, hidden, item)
        SELECT
            room_id,
            random() > 0.5, 
            id
        FROM items ORDER BY random() 
        LIMIT floor(random() * (max_items + 1));

        INSERT INTO room_enemies (room, enemy, current_hit_points)
        SELECT
            room_id,
            id,
            initial_hit_points
        FROM enemies 
        ORDER BY random() 
        LIMIT floor( random() * (max_enemies + 1 - min_enemies) + min_enemies );

        RETURN room_id;
    END;
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS generate_rooms(INTEGER);
CREATE FUNCTION generate_rooms(
    dungeon_id INTEGER, 
    OUT start_room INTEGER, 
    OUT final_room INTEGER
) AS $$
    DECLARE
        n_rooms_visible_path CONSTANT SMALLINT := 5;
        n_other_rooms CONSTANT SMALLINT := 5;
        previous_room INTEGER;
    BEGIN
        -- create start_room
        SELECT create_room(dungeon_id) INTO start_room;
        -- create rooms and visible path from start_room to final_room
        previous_room := start_room;
        FOR i IN 3..n_rooms_visible_path LOOP
            SELECT create_room(dungeon_id) INTO final_room;
            INSERT INTO gates(dungeon, room_from, room_to, hidden)
            VALUES (dungeon_id, previous_room, final_room, false);
            previous_room := final_room;
        END LOOP;
        -- create some other random room
        FOR i IN 1..n_other_rooms LOOP
            PERFORM create_room(dungeon_id);
        END LOOP;
        -- create random gates
        INSERT INTO gates (dungeon, room_from, room_to, hidden)
        SELECT dungeon_id, legal_gates.from_id, legal_gates.to_id, random() > 0.5
        FROM (
            (
                -- possible gates
                SELECT "from".id AS from_id, "to".id AS to_id
                FROM rooms AS "from" JOIN rooms AS "to"
                ON "from".id < "to".id
                AND "from".dungeon = dungeon_id
                AND "to".dungeon = dungeon_id
            ) EXCEPT (
                -- existent gates
                SELECT room_from, room_to FROM gates WHERE dungeon = dungeon_id
                UNION ALL
                SELECT room_to, room_from FROM gates WHERE dungeon = dungeon_id
            )
        ) AS legal_gates
        WHERE random() > 0.5; -- with probability of 1/2
        -- create the final final_room
        INSERT INTO rooms (dungeon, description)
        VALUES (
            dungeon_id, 
            (
                SELECT value FROM defaults WHERE key = 'final_room_description'
            )
        ) RETURNING id INTO final_room;
        -- create visible gate from previous final_room to final final_room
        INSERT INTO gates (dungeon, room_from, room_to, hidden)
        VALUES (dungeon_id, previous_room, final_room, false);
    END;
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS create_dungeon(VARCHAR);
CREATE FUNCTION create_dungeon(email VARCHAR(254))
RETURNS void AS $$
    DECLARE
        "character" INTEGER;
        dungeon INTEGER;
        dungeon_start_room INTEGER;
        dungeon_final_room INTEGER;
    BEGIN
        "character" := (SELECT id FROM characters WHERE "user" = email);
        INSERT INTO dungeons ("character")
            VALUES ("character") 
            RETURNING id INTO dungeon;
        SELECT start_room, final_room FROM generate_rooms(dungeon)
            INTO dungeon_start_room, dungeon_final_room;
        UPDATE dungeons SET
            final_room = dungeon_final_room,
            current_room = dungeon_start_room
            WHERE id = dungeon;
    END;
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS get_character(VARCHAR);
CREATE FUNCTION get_character(user_email VARCHAR(254)) 
RETURNS TABLE(
    name VARCHAR,
    description VARCHAR,
    strength SMALLINT,
    intellect SMALLINT,
    dexterity SMALLINT,
    constitution SMALLINT,
    room_attack_bonus SMALLINT,
    room_defence_bonus SMALLINT,
    room_wisdom_bonus SMALLINT,
    room_hit_points_bonus SMALLINT,
    attack SMALLINT,
    defence SMALLINT,
    wisdom SMALLINT,
    hit_points SMALLINT,
    equipped_defence_item INTEGER,
    equipped_attack_item INTEGER
)AS $$ 
    SELECT (
        C.name, 
        C.description, 
        C.strength,
        C.intellect,
        C.dexterity,
        C.constitution,
        C.room_attack_bonus,
        C.room_defence_bonus,
        C.room_wisdom_bonus,
        C.room_hit_points_bonus,
        ((C.strength + C.dexterity) / 2 + C.room_attack_bonus)::SMALLINT,
        ((C.constitution + C.dexterity) / 2 + C.room_defence_bonus)::SMALLINT,
        (C.intellect + C.room_wisdom_bonus)::SMALLINT,
        (C.constitution + C.room_hit_points_bonus)::SMALLINT,
        C.equipped_defence_item, 
        C.equipped_attack_item
    )
    FROM characters AS C WHERE C."user" = user_email;
$$ LANGUAGE 'sql';

DROP FUNCTION IF EXISTS get_character_items(VARCHAR);
CREATE FUNCTION get_character_items(user_email VARCHAR(254)) 
RETURNS TABLE (
    id INTEGER,
    name VARCHAR,
    description VARCHAR,
	attack SMALLINT,
    defence SMALLINT,
    wisdom SMALLINT,
    hit_points SMALLINT,
    category ITEM_CATEGORY
)AS $$ 
    (
        SELECT items.id, items.name, items.description, items.attack,
            items.defence, items.wisdom, items.hit_points, items.category
        FROM characters JOIN character_items
        ON characters.id = character_items."character"
        JOIN items
        ON items.id = character_items.item
        WHERE characters."user" = user_email
    )
    UNION
    (
        SELECT items.id, items.name, items.description, items.attack,
            items.defence, items.wisdom, items.hit_points, items.category
        FROM items JOIN characters
        ON items.id = characters.equipped_defence_item
        OR items.id = characters.equipped_attack_item
        WHERE characters."user" = user_email
    );
$$ LANGUAGE 'sql';

DROP FUNCTION IF EXISTS get_room(VARCHAR);
CREATE FUNCTION get_room(user_email VARCHAR(254)) 
RETURNS TABLE (
    id INTEGER,
    description VARCHAR
)AS $$ 
        SELECT rooms.id, rooms_descriptions.description
        FROM characters JOIN dungeons
        ON characters.id = dungeons."character"
        JOIN rooms
        ON rooms.id = dungeons.current_room
        JOIN rooms_descriptions
        ON rooms_descriptions.id = rooms.description
        WHERE characters."user" = user_email
$$ LANGUAGE 'sql';

DROP FUNCTION IF EXISTS get_room_items(VARCHAR);
CREATE FUNCTION get_room_items(user_email VARCHAR(254)) 
RETURNS TABLE (
    id INTEGER,
    name VARCHAR,
    description VARCHAR,
    attack SMALLINT,
    defence SMALLINT,
    wisdom SMALLINT,
    hit_points SMALLINT,
    category ITEM_CATEGORY
)AS $$ 
        SELECT items.id, items.name, items.description, items.attack,
            items.defence, items.wisdom, items.hit_points, items.category
        FROM characters JOIN dungeons
        ON characters.id = dungeons."character"
        JOIN room_items
        ON room_items.room = dungeons.current_room
        JOIN items
        ON items.id = room_items.item
        WHERE characters."user" = user_email
        AND room_items.hidden = false;
$$ LANGUAGE 'sql';

DROP FUNCTION IF EXISTS get_room_enemies(VARCHAR);
CREATE FUNCTION get_room_enemies(user_email VARCHAR(254)) 
RETURNS TABLE (
    id INTEGER,
    name VARCHAR,
    description VARCHAR,
    attack SMALLINT,
    defence SMALLINT,
    damage SMALLINT,
    hit_points SMALLINT
)AS $$ 
        SELECT 
            enemies.id, 
            enemies.name, 
            enemies.description, 
            enemies.attack, 
            enemies.defence, 
            enemies.damage, 
            room_enemies.current_hit_points
        FROM characters JOIN dungeons
        ON characters.id = dungeons."character"
        JOIN room_enemies
        ON room_enemies.room = dungeons.current_room
        JOIN enemies
        ON enemies.id = room_enemies.enemy
        WHERE characters."user" = user_email;
$$ LANGUAGE 'sql';

DROP FUNCTION IF EXISTS get_room_gates(VARCHAR);
CREATE FUNCTION get_room_gates(user_email VARCHAR(254)) 
RETURNS TABLE (
    id INTEGER,
    room INTEGER
) AS $$ 
        SELECT gates.id,
        CASE 
            WHEN dungeons.current_room = gates.room_from
            THEN gates.room_to
            ELSE gates.room_from
        END
        FROM characters JOIN dungeons
        ON characters.id = dungeons."character"
        JOIN gates
        ON gates.room_from = dungeons.current_room
        OR gates.room_to = dungeons.current_room
        WHERE characters."user" = user_email
        AND gates.hidden = false;
$$ LANGUAGE 'sql';

DROP FUNCTION IF EXISTS end_dungeon(VARCHAR);
CREATE FUNCTION end_dungeon(user_email VARCHAR(254)) RETURNS VOID AS $$
    DELETE FROM dungeons WHERE dungeons."character" = (
        SELECT id FROM characters WHERE "user" = user_email LIMIT 1
    );
$$ LANGUAGE 'sql';

DROP FUNCTION IF EXISTS follow_gate(VARCHAR, INTEGER);
CREATE FUNCTION follow_gate(user_email VARCHAR(254), gate_id INTEGER) RETURNS VOID AS $$
DECLARE
    room_over_gate INTEGER;
    user_character INTEGER;
    user_dungeon INTEGER;
    user_current_room INTEGER;
BEGIN
    SELECT characters.id
        FROM characters
        WHERE characters."user" = user_email
        LIMIT 1
        INTO user_character;
    SELECT dungeons.id, dungeons.current_room
        FROM dungeons
        WHERE dungeons."character" = user_character
        LIMIT 1
        INTO user_dungeon, user_current_room;
    SELECT
        CASE WHEN user_current_room = gates.room_from
            THEN gates.room_to
            ELSE gates.room_from
        END
        FROM gates
        WHERE gates.id = gate_id
        INTO room_over_gate;
    UPDATE dungeons SET
        current_room = room_over_gate
        WHERE dungeons."character" = user_character;
END;
$$ LANGUAGE 'plpgsql';

