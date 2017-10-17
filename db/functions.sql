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


DROP FUNCTION IF EXISTS delete_user(character varying);
CREATE FUNCTION delete_user( user_email VARCHAR(254)) RETURNS VOID AS
$$
    DELETE FROM users WHERE email = user_email;
$$ LANGUAGE 'sql';

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
DECLARE
    character_id INTEGER;
BEGIN
    if (
        strength_roll = intellect_roll
        OR strength_roll = dexterity_roll
        OR strength_roll = constitution_roll
        OR intellect_roll = dexterity_roll
        OR intellect_roll = constitution_roll
        OR dexterity_roll = constitution_roll
        ) THEN RAISE 'WRONG CHARACTER ROLLS';
    END IF;
    INSERT INTO characters (
        name, 
        description, 
        strength, 
        intellect, 
        dexterity, 
        constitution,
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
        email
    ) RETURNING id INTO character_id;
    INSERT INTO character_items ("character", item)
        SELECT character_id, value FROM defaults WHERE key like 'initial\_%\_item';
    UPDATE characters SET
        equipped_defence_item = (
            SELECT CI.id FROM character_items AS CI JOIN items AS I
                ON I.id = CI.item
            JOIN defaults AS D
                ON D.value = I.id
            WHERE D.key = 'initial_defence_item'
        ),
        equipped_attack_item = (
            SELECT CI.id FROM character_items AS CI JOIN items AS I
                ON I.id = CI.item
            JOIN defaults AS D
                ON D.value = I.id
            WHERE D.key = 'initial_attack_item'
        )
        WHERE characters.id = character_id;
    DELETE FROM rolls WHERE "user" = email;
END;
$$ LANGUAGE 'plpgsql';

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
CREATE FUNCTION create_dungeon(user_email VARCHAR(254))
RETURNS void AS $$
    DECLARE
        dungeon_id INTEGER;
        dungeon_start_room INTEGER;
        dungeon_final_room INTEGER;
    BEGIN
        INSERT INTO dungeons ("character", current_bonusless_hp)
            SELECT C.id, C.constitution
            FROM characters AS C
            WHERE C."user" = user_email
            RETURNING id INTO dungeon_id;
        SELECT start_room, final_room FROM generate_rooms(dungeon_id)
            INTO dungeon_start_room, dungeon_final_room;
        UPDATE dungeons SET
            final_room = dungeon_final_room,
            current_room = dungeon_start_room
            WHERE id = dungeon_id;
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
        D.room_attack_bonus,
        D.room_defence_bonus,
        D.room_wisdom_bonus,
        D.room_hit_points_bonus,
        ((C.strength + C.dexterity) / 2 + D.room_attack_bonus)::SMALLINT,
        ((C.constitution + C.dexterity) / 2 + D.room_defence_bonus)::SMALLINT,
        (C.intellect + D.room_wisdom_bonus)::SMALLINT,
        (D.current_bonusless_hp + D.room_hit_points_bonus)::SMALLINT,
        C.equipped_defence_item, 
        C.equipped_attack_item
    )
    FROM characters AS C JOIN dungeons AS D
    ON D."character" = C.id
    WHERE C."user" = user_email;
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
    SELECT character_items.id, items.name, items.description, items.attack,
        items.defence, items.wisdom, items.hit_points, items.category
    FROM characters JOIN character_items
    ON characters.id = character_items."character"
    JOIN items
    ON items.id = character_items.item
    WHERE characters."user" = user_email;
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
        SELECT room_items.id, items.name, items.description, items.attack,
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
            room_enemies.id, 
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

DROP FUNCTION IF EXISTS fight_enemy(VARCHAR, INTEGER);
CREATE FUNCTION fight_enemy(user_email VARCHAR(254), enemy_id INTEGER)
RETURNS TABLE (
    type VARCHAR,
    id INTEGER,
    damage SMALLINT,
    value SMALLINT,
    dice SMALLINT,
    hit BOOLEAN
) AS $$
DECLARE
    fight RECORD;
BEGIN
    CREATE TEMP TABLE fights ON COMMIT DROP AS
    SELECT 
        R.type::VARCHAR AS type,
        R.id::INTEGER AS id,
        R.damage::SMALLINT AS damage,
        R.value::SMALLINT AS value,
        R.dice::SMALLINT AS dice,
        R.value + R.dice > 12 AS hit
    FROM (
        (SELECT
            'attacking' AS type,
            enemy_id AS id,
            items.hit_points AS damage,
            ((characters.strength + characters.dexterity) / 2 + D.room_attack_bonus - enemies.defence) AS value,
            (floor(random() * 20) + 1) AS dice
        FROM characters JOIN character_items
        ON characters.equipped_attack_item = character_items.id
        JOIN items
        ON items.id = character_items.item
        JOIN dungeons AS D
        ON D."character" = characters.id
        JOIN room_enemies ON room_enemies.id = enemy_id
        JOIN enemies
        ON room_enemies.enemy = enemies.id
        WHERE characters."user" = user_email
        LIMIT 1)
    UNION
        (SELECT 
            'defending' AS "type",
            room_enemies.id AS id,
            enemies.damage AS damage,
            enemies.attack - ((characters.constitution + characters.dexterity) / 2 + D.room_defence_bonus) AS value,
            floor(random() * 20) + 1 AS dice
            FROM room_enemies JOIN enemies
            ON room_enemies.enemy = enemies.id
            JOIN dungeons
            ON room_enemies.room = dungeons.current_room
            JOIN characters
            ON dungeons."character" = characters.id
            JOIN dungeons AS D
            ON D."character" = characters.id
            WHERE characters."user" = user_email)
    ) AS R;
    UPDATE dungeons
        SET current_bonusless_hp = GREATEST(
            current_bonusless_hp - (
                SELECT SUM(fights.damage)
                FROM fights
                WHERE fights."type" = 'defending'
                AND fights.hit = true
            ),
            0
        );
    FOR fight IN (
        SELECT *
        FROM fights
        WHERE fights."type" = 'attacking'
        AND fights.hit = true
    ) LOOP
        IF (
            SELECT room_enemies.current_hit_points
            FROM room_enemies
            WHERE room_enemies.id = fight.id
        ) - fight.damage <= 0 THEN
            DELETE FROM room_enemies
            WHERE room_enemies.id = fight.id;
        ELSE
            UPDATE room_enemies
            SET current_hit_points = room_enemies.current_hit_points - fight.damage
            WHERE room_enemies.id = fight.id;
        END IF;
    END LOOP;
    RETURN QUERY SELECT * FROM fights;
END;
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS take_item(VARCHAR, INTEGER);
CREATE FUNCTION take_item(user_email VARCHAR(254), item_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    character_item_id INTEGER;
BEGIN
    INSERT INTO character_items ("character", item) (
        SELECT characters.id, room_items.item
            FROM room_items JOIN dungeons
                ON dungeons.current_room = room_items.room
            JOIN characters
                ON characters.id = dungeons."character"
            WHERE characters."user" = user_email
                AND room_items.id = item_id
        ) RETURNING id INTO character_item_id;
    DELETE FROM room_items WHERE room_items.id = item_id;
    RETURN character_item_id;
END;
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS use_item(VARCHAR, INTEGER);
CREATE FUNCTION use_item(user_email VARCHAR(254), character_item_id INTEGER)
RETURNS VOID AS $$
DECLARE
    character_id INTEGER;
BEGIN
    SELECT id FROM characters WHERE "user" = user_email INTO character_id;
    CASE (
        SELECT category FROM items JOIN character_items
        ON items.id = character_items.item
        WHERE character_items.id = character_item_id
    ) WHEN 'consumable' THEN
        UPDATE dungeons
            SET (
                room_attack_bonus,
                room_defence_bonus,
                room_wisdom_bonus,
                room_hit_points_bonus
            ) = (
                SELECT
                    room_attack_bonus + I.attack,
                    room_defence_bonus + I.defence,
                    room_wisdom_bonus + I.wisdom,
                    room_hit_points_bonus + I.hit_points
                FROM character_items AS CI JOIN items AS I
                ON CI.item = I.id
                WHERE CI."character" = character_id
                AND CI.id = character_item_id
            )
            WHERE dungeons."character" = character_id;
    WHEN 'defence' THEN
        UPDATE characters SET equipped_defence_item = character_item_id
        WHERE characters.id = character_id;
    WHEN 'attack' THEN
        UPDATE characters SET equipped_attack_item = character_item_id
        WHERE characters.id = character_id;
    END CASE;
END;
$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION reset_bonuses() RETURNS TRIGGER AS $$
BEGIN
    UPDATE dungeons SET
        (room_attack_bonus, room_defence_bonus, room_wisdom_bonus, room_hit_points_bonus) = (0,0,0,0);
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS room_changed ON dungeons CASCADE;
CREATE TRIGGER room_changed AFTER UPDATE
    ON dungeons
    FOR EACH ROW
    WHEN (NEW.current_room IS DISTINCT FROM OLD.current_room)
    EXECUTE PROCEDURE reset_bonuses();

