DROP FUNCTION IF EXISTS create_character(character varying,character varying,smallint,smallint,smallint,smallint,character varying);
CREATE FUNCTION create_character(
    name VARCHAR(20), 
    description VARCHAR,
    strength SMALLINT,
    intellect SMALLINT,
    dexterity SMALLINT,
    constitution SMALLINT,
    email VARCHAR(254)
) RETURNS void AS $$
    BEGIN
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
            strength, 
            intellect, 
            dexterity, 
            constitution, 
            email
        );
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
        final_room_description CONSTANT INTEGER := 0;
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
        VALUES (dungeon_id, final_room_description)
        RETURNING id INTO final_room;
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

DROP FUNCTION IF EXISTS dungeon_status(VARCHAR);
CREATE FUNCTION dungeon_status(user_email VARCHAR(254))
RETURNS JSONB AS $$
DECLARE
    json JSONB = to_jsonb('{"character": {"bag": []}}'::TEXT);
BEGIN
    RETURN to_jsonb('{"character": {"bag": []}}'::TEXT);
    json := jsonb_set(to_jsonb(json), '{"character", "bag"}', to_jsonb("character_bag")) FROM (

        SELECT items.name, items.description, items.attack, items.defence, items.wisdom, items.hit_points, items.category
        FROM characters JOIN character_items
        ON characters.id = character_items."character"
        JOIN items
        ON character_items.item = items.id
        WHERE characters."user" = user_email
    ) AS "character_bag";
    return json;
    json := (
        SELECT jsonb_set('{}', '{character}', to_jsonb("character")) FROM (
            SELECT characters.name, characters.description
            FROM characters
            WHERE characters."user" = user_email
        ) AS "character"
    );
END
$$ LANGUAGE 'plpgsql';

