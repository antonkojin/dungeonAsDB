INSERT INTO rooms_descriptions (description)
VALUES ('[description test]');
INSERT INTO rooms_descriptions (id, description)
VALUES (0, 'FINAL_ROOM');

INSERT INTO defaults (key, value) VALUES 
('final_room_description', 0),
('initial_defence_item', 1),
('initial_attack_item', 2);

INSERT INTO items (name, description, attack, defence, wisdom, hit_points, category)
VALUES 
    ('shield1', 'description6', 0, 0, 0, 0, 'defence'),
    ('sword1', 'description5', 0, 0, 0, 99, 'attack'),
    ('cons1', 'description1', 0, 0, 0, 0, 'consumable'),
    ('cons2', 'description2', 0, 0, 0, 0, 'consumable'),
    ('cons3', 'description3', 0, 0, 0, 0, 'consumable'),
    ('cons4', 'description4', 0, 0, 0, 0, 'consumable');

INSERT INTO enemies (name, description, attack, defence, initial_hit_points, damage)
VALUES 
    ('enemy1', 'description1', 0, 0, 1, 0),
    ('enemy2', 'description2', 0, 0, 1, 0),
    ('enemy3', 'description3', 0, 0, 1, 0),
    ('enemy4', 'description4', 0, 0, 1, 0),
    ('enemy5', 'description5', 0, 0, 1, 0),
    ('enemy6', 'description6', 0, 0, 1, 0);

-- SELECT create_dungeon('test@test.com');
