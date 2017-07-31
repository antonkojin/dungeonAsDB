DROP TABLE IF EXISTS character_items;
DROP TABLE IF EXISTS room_enemies;
DROP TABLE IF EXISTS room_items;
ALTER TABLE IF EXISTS rooms DROP CONSTRAINT IF EXISTS rooms_dungeon_fkey;
DROP TABLE IF EXISTS gates;
DROP TABLE IF EXISTS dungeons;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS rooms_descriptions;
DROP TABLE IF EXISTS characters;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS items;
DROP TYPE IF EXISTS ITEM_CATEGORY;
DROP TABLE IF EXISTS enemies;

CREATE TYPE ITEM_CATEGORY AS ENUM ('attack', 'defence', 'consumable');
CREATE TABLE items (
	id SERIAL PRIMARY KEY,
	name VARCHAR(20) NOT NULL,
	description VARCHAR NOT NULL,
	attack SMALLINT NOT NULL, -- [-6,6]
    defence SMALLINT NOT NULL, -- [-6,6]
    wisdom SMALLINT NOT NULL, -- [-6,6]
    hit_points SMALLINT NOT NULL, -- [-6,6]
	category ITEM_CATEGORY NOT NULL
);

CREATE TABLE users (
	email VARCHAR(254) PRIMARY KEY,
	nickname VARCHAR(20) NOT NULL UNIQUE,
	password_hash CHARACTER(93) NOT NULL
);

CREATE TABLE characters (
	id SERIAL PRIMARY KEY,
	name VARCHAR(20) NOT NULL,
	description VARCHAR,
	strength SMALLINT NOT NULL CHECK (strength >= 3 AND strength <= 18),
	intellect SMALLINT NOT NULL CHECK (strength >= 3 AND strength <= 18),
	dexterity SMALLINT NOT NULL CHECK (strength >= 3 AND strength <= 18),
	constitution SMALLINT NOT NULL CHECK (strength >= 3 AND strength <= 18),
	equipped_defence_item INTEGER REFERENCES items(id),
	equipped_attack_item INTEGER REFERENCES items(id),
	"user" VARCHAR(254) REFERENCES users(email) NOT NULL UNIQUE,
--	attack = (strength + dexterity) / 2 + bonus
--	defence = (constitution + dextrity) / 2 + bonus
--	wisdom = intellect + bonus
--	hit_points = constitution + bonus
	room_attack_bonus SMALLINT,
	room_defence_bonus SMALLINT,
	room_wisdom_bonus SMALLINT,
	room_hit_points_bonus SMALLINT
);

CREATE TABLE rooms_descriptions (
    id SERIAL PRIMARY KEY,
	description VARCHAR NOT NULL
);

CREATE TABLE rooms (
	-- two special rooms: start_room, final_room
	id SERIAL PRIMARY KEY,
	description INTEGER NOT NULL REFERENCES rooms_descriptions(id),
	description VARCHAR NOT NULL,
    visited BOOLEAN NOT NULL DEFAULT FALSE,
    -- if a room was visited then you can see it througth the gate
	dungeon INTEGER NOT NULL
);

CREATE TABLE dungeons (
	id SERIAL PRIMARY KEY,
	character INTEGER REFERENCES characters(id) NOT NULL UNIQUE,
	current_room INTEGER REFERENCES rooms(id),
	final_room INTEGER REFERENCES rooms(id)
);

ALTER TABLE rooms ADD CONSTRAINT rooms_dungeon_fkey FOREIGN KEY (dungeon) REFERENCES dungeons(id);

CREATE TABLE character_items (
	id SERIAL PRIMARY KEY,
	character INTEGER REFERENCES characters(id) NOT NULL,
	item INTEGER REFERENCES items(id) NOT NULL
);

CREATE TABLE enemies (
	id SERIAL PRIMARY KEY,
	name VARCHAR(20) NOT NULL,
	description VARCHAR NOT NULL,
	attack SMALLINT NOT NULL,
	defence SMALLINT NOT NULL,
	initial_hit_points SMALLINT NOT NULL,
	damage SMALLINT NOT NULL
);

CREATE TABLE room_enemies (
	id SERIAL PRIMARY KEY,
	room INTEGER REFERENCES rooms(id) NOT NULL,
	enemy INTEGER REFERENCES enemies(id) NOT NULL,
	current_hit_points SMALLINT NOT NULL
);

CREATE TABLE room_items (
	id SERIAL PRIMARY KEY,
	room INTEGER REFERENCES rooms(id) NOT NULL,
	item INTEGER REFERENCES items(id) NOT NULL,
	hidden BOOLEAN NOT NULL
);

CREATE TABLE gates (
	id SERIAL PRIMARY KEY,
    dungeon INTEGER REFERENCES dungeons(id) NOT NULL,
	room_from INTEGER REFERENCES rooms(id) NOT NULL,
	room_to INTEGER REFERENCES rooms(id) NOT NULL,
	hidden BOOLEAN NOT NULL,
    UNIQUE (dungeon, room_from, room_to),
    UNIQUE (dungeon, room_to, room_from)
);

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
RETURNS TABLE(
   n NUMERIC
) AS $$
    BEGIN
        SELECT 1;
        /*
        return (
            SELECT
                -- room
                rooms_descriptions.description,
                
                -- character
                characters.name,
                characters.description,
                characters.strength,
                characters.intellect,
                characters.dexterity,
                caracters.constitution,
                characters.room_attack_bonus,
                characters.room_defence_bonus,
                characters.room_wisdom_bonus,
                characters.room_hit_points_bonus,
                characters.equipped_defence_item,
                characters.equipped_attack_item
            FROM (
                dungeons
                    JOIN
                rooms
                    JOIN
                room_descriptions
                    JOIN
                room_items
                    JOIN
                items
                    JOIN
                room_enemies
                    JOIN
                enemies
                    JOIN
                gates
                    JOIN
                characters
                    JOIN
                character_items
            ) ON dungeons."character" = characters.id
            AND rooms.id = dungeons.current_room
            AND rooms_descriptions.id = rooms.description
            AND room_items.room = dungeons.current_room
            AND room_items.hidden = false
            AND room_items.item = items.id
            WHERE characters.email = user_email
        );
        */
    END;
$$ LANGUAGE 'plpgsql';

