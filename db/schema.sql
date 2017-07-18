DROP TABLE IF EXISTS character_items;
DROP TABLE IF EXISTS characters;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS items;
DROP TYPE IF EXISTS CATEGORY;

CREATE TYPE CATEGORY AS ENUM ('attack', 'defence', 'consumable');
CREATE TABLE items (
	id SERIAL PRIMARY KEY,
	name VARCHAR(20) NOT NULL,
	description VARCHAR NOT NULL,
	attack SMALLINT NOT NULL, -- [-6,6]
        defence SMALLINT NOT NULL, -- [-6,6]
        wisdom SMALLINT NOT NULL, -- [-6,6]
        hit_points SMALLINT NOT NULL, -- [-6,6]
	category CATEGORY NOT NULL

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

CREATE TABLE character_items (
	id SERIAL PRIMARY KEY,
	character INTEGER REFERENCES characters(id) NOT NULL,
	item INTEGER REFERENCES items(id) NOT NULL,
	times SMALLINT NOT NULL,
	UNIQUE (character, item)
);

CREATE TABLE enemies (
	id SERIAL PRIMARY KEY,
	name VARCHAR(20) NOT NULL,
	description VARCHAR NOT NULL,
	attack SMALLINT NOT NULL,
	defence SMALLINT NOT NULL,
	hit_points SMALLINT NOT NULL,
	damage SMALLINT NOT NULL
);















