DROP TABLE IF EXISTS character_items;
DROP TABLE IF EXISTS room_enemies;
DROP TABLE IF EXISTS room_items;
ALTER TABLE rooms DROP CONSTRAINT IF EXISTS rooms_dungeon_fkey;
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
	nickname VARCHAR(20) NOT NULL,
	email VARCHAR(254) NOT NULL,
	password_hash BYTEA NOT NULL
);
	
CREATE TABLE characters (
	id SERIAL PRIMARY KEY,
	name VARCHAR(20) NOT NULL,
	description VARCHAR,
	strength SMALLINT, -- [3,18]
	intellect SMALLINT, -- [3,18]
	dexterity SMALLINT, -- [3,18]
	constitution SMALLINT, -- [3,18]
	equipped_defence_item INTEGER REFERENCES items(id),
	equipped_attack_item INTEGER REFERENCES items(id),
	"user" INTEGER REFERENCES users(id)
--	attack = (strength + dexterity) / 2 + bonus
--	defence = (constitution + dextrity) / 2 + bonus
--	wisdom = intellect + bonus
--	hit_points = constitution + bonus
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










