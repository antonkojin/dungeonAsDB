INSERT INTO rooms_descriptions (description)
VALUES ('[description test]');
INSERT INTO rooms_descriptions (id, description)
VALUES (0, 'FINAL_ROOM');

INSERT INTO defaults (key, value) VALUES 
('final_room_description', 0),
('initial_defence_item', 1),
('initial_attack_item', 2),
('initial_consumable_item', 3);

INSERT INTO items (name, description, attack, defence, wisdom, hit_points, category)
VALUES 
    ('shield1', 'description6', 0, 0, 0, 0, 'defence'),
    ('sword1', 'description5', 0, 0, 0, 99, 'attack'),
    ('cons1', 'description1', 3, -3, 6, -2, 'consumable'),
    ('shield2', 'description7', 0, 0, 0, 0, 'defence'),
    ('sword2', 'description8', 0, 0, 0, 99, 'attack'),
    ('shield3', 'description9', 0, 0, 0, 0, 'defence'),
    ('sword3', 'description10', 0, 0, 0, 99, 'attack'),
    ('cons2', 'description2', 0, 0, 0, 0, 'consumable'),
    ('cons3', 'description3', 0, 0, 0, 0, 'consumable'),
    ('cons4', 'description4', 0, 0, 0, 0, 'consumable');

INSERT INTO enemies (name, description, attack, defence, initial_hit_points, damage)
VALUES 
    ('enemy1', 'description1', 90, 0, 1, 1),
    ('enemy2', 'description2', 90, 0, 1, 1),
    ('enemy3', 'description3', 90, 0, 1, 1),
    ('enemy4', 'description4', 90, 0, 1, 1),
    ('enemy5', 'description5', 90, 0, 1, 1),
    ('enemy6', 'description6', 90, 0, 1, 1);

