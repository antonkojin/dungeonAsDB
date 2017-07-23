DROP TABLE IF EXISTS character_items;
DROP TABLE IF EXISTS room_enemies;
DROP TABLE IF EXISTS room_items;
ALTER TABLE IF EXISTS rooms DROP CONSTRAINT IF EXISTS rooms_dungeon_fkey;
DROP TABLE IF EXISTS dungeons;
DROP TABLE IF EXISTS gates;
DROP TABLE IF EXISTS rooms;
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
	id SERIAL PRIMARY KEY,
	nickname VARCHAR(20) NOT NULL UNIQUE,
	email VARCHAR(254) NOT NULL UNIQUE,
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
	"user" INTEGER REFERENCES users(id) NOT NULL UNIQUE,
--	attack = (strength + dexterity) / 2 + bonus
--	defence = (constitution + dextrity) / 2 + bonus
--	wisdom = intellect + bonus
--	hit_points = constitution + bonus
	room_attack_bonus SMALLINT,
	room_defence_bonus SMALLINT,
	room_wisdom_bonus SMALLINT,
	room_hit_points_bonus SMALLINT
);

CREATE TABLE rooms (
	-- two special rooms: start_room, final_room
	id SERIAL PRIMARY KEY,
	description VARCHAR NOT NULL,
	dungeon INTEGER NOT NULL
);

CREATE TABLE dungeons (
	id SERIAL PRIMARY KEY,
	character INTEGER REFERENCES characters(id) NOT NULL,
	current_room INTEGER REFERENCES rooms(id) NOT NULL,
	start_room INTEGER REFERENCES rooms(id) NOT NULL,
	final_room INTEGER REFERENCES rooms(id) NOT NULL
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
	room_from INTEGER REFERENCES rooms(id) NOT NULL,
	room_to INTEGER REFERENCES rooms(id) NOT NULL,
	hidden BOOLEAN NOT NULL
);

DROP FUNCTION IF EXISTS create_character(character varying,character varying,smallint,smallint,smallint,smallint,character varying);
CREATE FUNCTION create_character(
    name VARCHAR(20), 
    description VARCHAR,
    strength SMALLINT,
    intellect SMALLINT,
    dexterity SMALLINT,
    constitution SMALLINT,
    user_email VARCHAR(254)
) RETURNS void AS $$
    DECLARE
        user_id INTEGER;
    BEGIN
        user_id := (SELECT id FROM "users" WHERE users.email = user_email);
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
            user_id
        );
    END;
$$ LANGUAGE 'plpgsql';
