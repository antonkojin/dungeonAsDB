INSERT INTO users (email, nickname, password_hash)
VALUES ('test@test.com', 'nickname', 'password_hash');

INSERT INTO characters (name, description, strength, intellect, dexterity, constitution, "user")
VALUES ('test_name', 'test_description', 3, 3, 3, 3, 'test@test.com');

/*
INSERT INTO dungeons(character)
VALUES(1);
*/

INSERT INTO rooms_descriptions (description)
VALUES ('[description test]');
INSERT INTO rooms_descriptions (id, description)
VALUES (0, 'FINAL_ROOM');

INSERT INTO items (name, description, attack, defence, wisdom, hit_points, category)
VALUES 
    ('cons1', 'description1', 0, 0, 0, 0, 'consumable'),
    ('cons2', 'description2', 0, 0, 0, 0, 'consumable'),
    ('cons3', 'description3', 0, 0, 0, 0, 'consumable'),
    ('cons4', 'description4', 0, 0, 0, 0, 'consumable'),
    ('sword1', 'description5', 0, 0, 0, 0, 'attack'),
    ('shield1', 'description6', 0, 0, 0, 0, 'defence');

INSERT INTO enemies (name, description, attack, defence, 
    initial_hit_points, damage
) VALUES 
    ('enemy1', 'description1', 0, 0, 1, 0),
    ('enemy2', 'description2', 0, 0, 1, 0),
    ('enemy3', 'description3', 0, 0, 1, 0),
    ('enemy4', 'description4', 0, 0, 1, 0),
    ('enemy5', 'description5', 0, 0, 1, 0),
    ('enemy6', 'description6', 0, 0, 1, 0);

SELECT create_dungeon('test@test.com');
