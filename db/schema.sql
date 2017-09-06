DROP TABLE IF EXISTS defaults CASCADE;
DROP TABLE IF EXISTS character_items CASCADE;
DROP TABLE IF EXISTS room_enemies CASCADE;
DROP TABLE IF EXISTS room_items CASCADE;
ALTER TABLE IF EXISTS rooms DROP CONSTRAINT IF EXISTS rooms_dungeon_fkey CASCADE;
DROP TABLE IF EXISTS gates CASCADE;
DROP TABLE IF EXISTS dungeons CASCADE;
DROP TABLE IF EXISTS rooms CASCADE;
DROP TABLE IF EXISTS rooms_descriptions CASCADE;
DROP TABLE IF EXISTS characters CASCADE;
DROP TABLE IF EXISTS rolls CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS items CASCADE;
DROP TYPE IF EXISTS ITEM_CATEGORY CASCADE;
DROP TABLE IF EXISTS enemies CASCADE;

CREATE table defaults (
    key VARCHAR PRIMARY KEY,
    value INTEGER NOT NULL
);

CREATE TABLE users (
	email VARCHAR(254) PRIMARY KEY,
	nickname VARCHAR(20) NOT NULL UNIQUE,
	password_hash CHARACTER(93) NOT NULL
);

CREATE TABLE rolls (
    id SERIAL PRIMARY KEY,
    "user" varchar(254) NOT NULL REFERENCES users(email) ON DELETE CASCADE,
    dice_1 SMALLINT NOT NULL,
    dice_2 SMALLINT NOT NULL,
    dice_3 SMALLINT NOT NULL
);

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
	"user" VARCHAR(254) NOT NULL UNIQUE REFERENCES users(email) ON DELETE CASCADE
--	attack = (strength + dexterity) / 2 + bonus
--	defence = (constitution + dexterity) / 2 + bonus
--	wisdom = intellect + bonus
--	hit_points = constitution + bonus
);

CREATE TABLE rooms_descriptions (
    id SERIAL PRIMARY KEY,
	description VARCHAR NOT NULL
);

CREATE TABLE rooms (
	-- two special rooms: start_room, final_room
	id SERIAL PRIMARY KEY,
	description INTEGER NOT NULL REFERENCES rooms_descriptions(id),
    visited BOOLEAN NOT NULL DEFAULT FALSE,
    -- if a room was visited then you can see it througth the gate
	dungeon INTEGER NOT NULL
);

CREATE TABLE dungeons (
	id SERIAL PRIMARY KEY,
	character INTEGER NOT NULL UNIQUE REFERENCES characters(id) ON DELETE CASCADE,
    current_bonusless_hp SMALLINT NOT NULL,
	room_attack_bonus SMALLINT NOT NULL DEFAULT 0,
	room_defence_bonus SMALLINT NOT NULL DEFAULT 0,
	room_wisdom_bonus SMALLINT NOT NULL DEFAULT 0,
	room_hit_points_bonus SMALLINT NOT NULL DEFAULT 0,
	current_room INTEGER REFERENCES rooms(id),
	final_room INTEGER REFERENCES rooms(id)
);

ALTER TABLE rooms ADD CONSTRAINT rooms_dungeon_fkey FOREIGN KEY (dungeon) REFERENCES dungeons(id) ON DELETE CASCADE;

CREATE TABLE character_items (
	id SERIAL PRIMARY KEY,
	character INTEGER NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
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
	room INTEGER NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
	enemy INTEGER REFERENCES enemies(id) NOT NULL,
	current_hit_points SMALLINT NOT NULL
);

CREATE TABLE room_items (
	id SERIAL PRIMARY KEY,
	room INTEGER NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
	item INTEGER REFERENCES items(id) NOT NULL,
	hidden BOOLEAN NOT NULL
);

CREATE TABLE gates (
	id SERIAL PRIMARY KEY,
    dungeon INTEGER NOT NULL REFERENCES dungeons(id) ON DELETE CASCADE,
	room_from INTEGER NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
	room_to INTEGER NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
	hidden BOOLEAN NOT NULL,
    UNIQUE (dungeon, room_from, room_to),
    UNIQUE (dungeon, room_to, room_from)
);
