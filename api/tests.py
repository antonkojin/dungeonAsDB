#!/usr/bin/env python3

import unittest
import requests
from requests import codes
from sys import argv as args
import sys
from os.path import dirname, realpath

heroku = len(args) >= 2 and args[1] == 'heroku'
if heroku:
    sys.argv = args[:1] + args[2:]

if heroku:
    host = 'https://progetto-db.herokuapp.com/'
else:
    host = 'http://localhost:8000/'

if heroku:
    init_db_script = (
        'heroku run node db/heroku_init_db.js '
        ' db/schema.sql'
        ' db/data.sql'
        ' db/functions.sql'
    )
else:
    init_db_script = dirname(realpath(__file__)) + (
        '/../db/docker_init_db.sh'
        'schema.sql'
        'functions.sql'
        'data.sql'
    )


def url(path):
    return host + path


user = {
    'email': 'test@example.com',
    'nickname': 'test_nickname',
    'password': 'test_password'
}

auth = (
    user['email'],
    user['password']
)


class TestDungeonAsDB(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        from os import devnull
        import subprocess
        with open(devnull, 'w') as DEVNULL:
            # TODO: if db init fails, fail tests, too
            subprocess.call(init_db_script, shell=True,
                            stdout=DEVNULL, stderr=subprocess.STDOUT)

    @classmethod
    def tearDownClass(cls):
        cls.setUpClass()

    def setUp(self):
        self.tearDown()

    def tearDown(self):
        requests.delete(url('user'), auth=auth)

    def test_signup(self):
        request_data = user
        response = requests.post(url('user'), data=request_data)
        self.assertIn(
            response.status_code,
            [codes.no_content, codes.conflict]
        )

    def test_login(self):
        self.test_signup()
        response = requests.get(url('user'), auth=auth)
        self.assertEqual(
            response.status_code,
            codes.ok
        )
        self.assertEqual(response.json()['email'], user['email'])
        self.assertEqual(response.json()['nickname'], user['nickname'])

    def test_cant_login_with_wrong_password(self):
        self.test_signup()
        auth = (
            user['email'],
            user['password'] + '_wrong'
        )
        response = requests.get(url('user'), auth=auth)
        self.assertEqual(
            response.status_code,
            codes.unauthorized
        )

    def test_create_character(self):
        self.test_signup()
        rolls = requests.get(url('dices'), auth=auth).json()
        self.assertEqual(len(rolls), 5)
        for roll in rolls:
            self.assertTrue(roll['dice_1'] >= 1 and roll['dice_1'] <= 6)
            self.assertTrue(roll['dice_2'] >= 1 and roll['dice_2'] <= 6)
            self.assertTrue(roll['dice_3'] >= 1 and roll['dice_3'] <= 6)
        data = {
            'name': 'test_character_name',
            'description': 'test_character_not_very_long_description',
            'strength': rolls[0]['id'],
            'intellect': rolls[1]['id'],
            'dexterity': rolls[2]['id'],
            'constitution': rolls[3]['id']
        }
        response = requests.post(url('character'), auth=auth, data=data)
        self.assertEqual(
            response.status_code,
            codes.created
        )

    def test_cant_roll_twice_character_dices(self):
        self.test_signup()
        rolls_response = requests.get(url('dices'), auth=auth)
        self.assertEqual(
            rolls_response.status_code,
            codes.ok
        )
        rolls = rolls_response.json()
        another_rolls_response = requests.get(url('dices'), auth=auth)
        self.assertEqual(
            another_rolls_response.status_code,
            codes.ok
        )
        self.assertEqual(rolls, another_rolls_response.json())
        data = {
            'name': 'test_character_name',
            'description': 'test character not very long description',
            'strength': rolls[0]['id'],
            'intellect': rolls[1]['id'],
            'dexterity': rolls[2]['id'],
            'constitution': rolls[3]['id']
        }
        response = requests.post(url('character'), auth=auth, data=data)
        self.assertEqual(
            response.status_code,
            codes.created
        )
        self.assertEqual(
            requests.get(url('dices'), auth=auth).status_code,
            codes.not_found
        )

    def test_cant_create_another_character(self):
        self.test_signup()
        rolls = requests.get(url('dices'), auth=auth).json()
        data = {
            'name': 'test_character_name',
            'description': 'test character not very long description',
            'strength': rolls[0]['id'],
            'intellect': rolls[1]['id'],
            'dexterity': rolls[2]['id'],
            'constitution': rolls[3]['id']
        }
        self.assertEqual(
            requests.post(url('character'), auth=auth, data=data).status_code,
            codes.created
        )
        self.assertIn(
            requests.post(url('character'), auth=auth, data=data).status_code,
            [
                codes.conflict,
                codes.bad_request
            ]
        )

    def test_cant_create_wrong_character(self):
        self.test_signup()
        rolls = requests.get(url('dices'), auth=auth).json()
        data = {
            'name': 'test_character_name',
            'description': 'test_character_not_very_long_description',
            'strength': rolls[0]['id'],
            'intellect': rolls[1]['id'],
            'dexterity': rolls[0]['id'],
            'constitution': rolls[2]['id']
        }
        response = requests.post(url('character'), auth=auth, data=data)
        self.assertEqual(
            response.status_code,
            codes.bad_request
        )

    def test_start_dungeon(self):
        self.test_create_character()
        response = requests.post(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code,
            codes.created
        )

    def test_cant_start_another_dungeon(self):
        self.test_start_dungeon()
        requests.post(url('dungeon'), auth=auth)
        response = requests.post(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code,
            codes.conflict
        )

    def test_dungeon_status(self):
        self.test_start_dungeon()
        response = requests.get(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code,
            codes.ok
        )
        response_json = response.json()
        self.assertIn('character', response_json)
        self.assertIn('room', response_json)

        character = response_json['character']
        self.assertIn('name', character)
        self.assertIn('description', character)
        self.assertIn('strength', character)
        self.assertIn('intellect', character)
        self.assertIn('dexterity', character)
        self.assertIn('constitution', character)
        self.assertIn('room_attack_bonus', character)
        self.assertIn('room_defence_bonus', character)
        self.assertIn('room_wisdom_bonus', character)
        self.assertIn('room_hit_points_bonus', character)
        self.assertIn('attack', character)
        self.assertIn('defence', character)
        self.assertIn('wisdom', character)
        self.assertIn('hit_points', character)
        self.assertIn('equipped_defence_item', character)
        self.assertIn('equipped_attack_item', character)
        self.assertIn('bag', character)

        bag = character['bag']
        self.assertTrue(len(bag) >= 2)
        for item in bag:
            self.assertIn('id', item)
            self.assertIn('name', item)
            self.assertIn('description', item)
            self.assertIn('attack', item)
            self.assertIn('defence', item)
            self.assertIn('wisdom', item)
            self.assertIn('hit_points', item)
            self.assertIn('category', item)

        room = response_json['room']
        self.assertIn('id', room)
        self.assertIn('description', room)
        self.assertIn('items', room)
        self.assertIn('enemies', room)
        self.assertIn('gates', room)

        room_items = room['items']
        for item in room_items:
            self.assertIn('id', item)
            self.assertIn('name', item)
            self.assertIn('description', item)
            self.assertIn('attack', item)
            self.assertIn('defence', item)
            self.assertIn('wisdom', item)
            self.assertIn('hit_points', item)
            self.assertIn('category', item)

        room_enemies = room['enemies']
        for enemy in room_enemies:
            self.assertIn('id', enemy)
            self.assertIn('name', enemy)
            self.assertIn('description', enemy)
            self.assertIn('attack', enemy)
            self.assertIn('defence', enemy)
            self.assertIn('hit_points', enemy)
            self.assertIn('damage', enemy)

        room_gates = room['gates']
        for gate in room_gates:
            self.assertIn('id', gate)
            self.assertIn('room', gate)

    def test_end_dungeon(self):
        self.test_start_dungeon()
        self.assertEqual(
            requests.post(url('dungeon'), auth=auth).status_code,
            codes.conflict
        )
        self.assertEqual(
            requests.delete(url('dungeon'), auth=auth).status_code,
            codes.ok
        )
        self.assertEqual(
            requests.post(url('dungeon'), auth=auth).status_code,
            codes.created
        )

    def test_delete_user(self):
        self.test_signup()
        response = requests.delete(url('user'), auth=auth)
        self.assertEqual(
            response.status_code,
            codes.ok
        )

    def test_follow_gate_to_other_room(self):
        self.test_start_dungeon()
        old_room = requests.get(url('dungeon'), auth=auth).json()['room']
        gate_id = old_room['gates'][0]['id']
        response = requests.get(
            url('dungeon/gate/{gate_id}'.format(gate_id=gate_id)),
            auth=auth
        )
        self.assertEqual(
            response.status_code,
            codes.ok
        )
        new_room = requests.get(url('dungeon'), auth=auth).json()['room']
        self.assertNotEqual(
            old_room['id'],
            new_room['id']
        )
        self.assertEqual(
            old_room['gates'][0]['room'],
            new_room['id']
        )

    def test_fight(self):
        # A vs B
        # X = A.att - B.dif
        # if X + 1d20 > 12 then
        #   B.pf = B.pf - (A.arma.pf || A.danno)
        self.test_start_dungeon()
        response = requests.get(url('dungeon'), auth=auth)
        character = response.json()['character']

        enemies = response.json()['room']['enemies']
        if len(enemies) < 1:
            self.skipTest('no enemies to fight')
        enemy = enemies[0]
        response = requests.post(
            url('dungeon/enemy/{enemy_id}'.format(enemy_id=enemy['id'])),
            auth=auth
        )
        self.assertEqual(response.status_code, codes.ok)
        after_attack_status = requests.get(url('dungeon'), auth=auth).json()
        fights = response.json()
        self.assertEqual(len(fights), len(enemies) + 1)
        for fight in fights:
            if fight['type'] == 'attacking':
                self.assertEqual(fight['id'], enemy['id'])
                value = character['attack'] - enemy['defence']
                if fight['hit']:
                    if enemy['hit_points'] - fight['damage'] <= 0:
                        self.assertEqual(
                            len(list(filter(
                                lambda e: e['id'] == enemy['id'],
                                after_attack_status['room']['enemies']
                            ))),
                            0
                        )
                    else:
                        self.assertEqual(
                            [
                                e['hit_points']
                                for e in after_attack_status['room']['enemies']
                                if e['id'] == enemy['id']
                            ][0],
                            enemy['hit_points'] - fight['damage']
                        )
            elif fight['type'] == 'defending':
                self.assertIn(
                    fight['id'],
                    map(lambda enemy: enemy['id'], enemies)
                )
                value = [
                    enemy['attack'] - character['defence']
                    for enemy in enemies if enemy['id'] == fight['id']
                ][0]
            self.assertEqual(fight['value'], value)
            self.assertIn(fight['dice'], range(1, 21))
            self.assertEqual(
                value + fight['dice'] > 12,
                fight['hit']
            )
            all_damage = sum([
                f['damage']
                for f in fights
                if f['type'] == 'defending' and f['hit']
            ])
            self.assertEqual(
                after_attack_status['character']['hit_points'],
                character['hit_points'] - all_damage
            )

    def fight_til_clear_or_die(self):
        dungeon = requests.get(url('dungeon'), auth=auth).json()
        there_are_enemies = len(dungeon['room']['enemies']) > 0
        me_alive = dungeon['character']['hit_points'] > 0
        while there_are_enemies and me_alive :
            enemies = dungeon['room']['enemies']
            enemy = enemies[0]
            requests.post(
                url('dungeon/enemy/{enemy_id}'.format(enemy_id=enemy['id'])),
                auth=auth)
            dungeon = requests.get(url('dungeon'), auth=auth).json()
            there_are_enemies = len(dungeon['room']['enemies']) > 0
            me_alive = dungeon['character']['hit_points'] > 0
        return me_alive

    def test_take_item_from_room(self):
        self.test_start_dungeon()
        dungeon = requests.get(url('dungeon'), auth=auth).json()
        items = dungeon['room']['items']
        while len(items) == 0:
            import random
            gate_id = random.choice(dungeon['room']['gates'])['id']
            requests.get(
                url('dungeon/gate/{gate_id}'.format(gate_id=gate_id)),
                auth=auth
            )
            dungeon = requests.get(url('dungeon'), auth=auth).json()
            items = dungeon['room']['items']
        if not self.fight_til_clear_or_die():
            self.skipTest('died while clearing room from enemies')
        character_items = dungeon['character']['bag']
        item_id = items[0]['id']
        response = requests.post(
            url('dungeon/item/{item}'.format(item=item_id)),
            auth=auth
        )
        self.assertEqual(
            response.status_code,
            codes.ok
        )
        self.assertEqual(type(response.json()['id']), type(1))
        updated_character_items = requests.get(url('dungeon'), auth=auth).json()['character']['bag']
        self.assertEqual(
            len(updated_character_items),
            len(character_items) + 1
        )

    def test_use_consumable_item(self):
        self.test_start_dungeon()
        dungeon = requests.get(url('dungeon'), auth=auth).json()
        character = dungeon['character']
        items = character['bag']
        consumable_items = list(filter(
            lambda i: i['category'] == 'consumable',
            items
        ))
        if len(consumable_items) == 0:
            self.skipTest('can\'t test, don\'t have consumable items')
        item = consumable_items[0]
        response = requests.post(
            url('dungeon/bag/{item}'.format(item=item['id'])),
            auth=auth
        )
        self.assertEqual(
            response.status_code,
            codes.ok
        )
        updated_character = requests.get(url('dungeon'), auth=auth).json()['character']
        self.assertEqual(
            updated_character['attack'],
            character['attack'] + item['attack']
        )
        self.assertEqual(
            updated_character['defence'],
            character['defence'] + item['defence']
        )
        self.assertEqual(
            updated_character['wisdom'],
            character['wisdom'] + item['wisdom']
        )
        self.assertEqual(
            updated_character['hit_points'],
            character['hit_points'] + item['hit_points']
        )

    @unittest.skip('')
    def test_equip_wearable_item(self):
        response = requests.get(url('dungeon'), auth=auth)
        character = response.json()['character']
        items = character['bag']
        wearable_items = [
            item
            for item in items
            if item['type'] == 'defence'
            and (
                item['id'] != character['equipped_defece_item']['id']
                if character['equipped_defence_item']
                else None
            )
            and (
                item['id'] != character['equipped_attack_item']['id']
                if character['equipped_attack_item']
                else None
            )
        ]
        if len(wearable_items) == 0:
            self.skipTest('can\'t test, don\'t have other wearable items')
        item = wearable_items[0]
        response = requests.put(
            url('dungeon/bag/{item}'.format(item=item['id'])),
            auth=auth
        )
        self.assertEqual(
            response.status_code,
            codes.ok
        )
        updated_character = response.json()['character']
        self.assertEqual(
            updated_character[item['type'] + '_item'],
            item
        )
        self.assertNotEqual(
            updated_character[item['type'] + '_item'][id],
            character[item['type'] + '_item'][id]
            if character[item['type'] + '_item']
            else None
        )

        # TODO: test_cant_take_too_many_items

        # TODO: test_drop_bonus_on_room_change

if __name__ == '__main__':
    from colour_runner.runner import ColourTextTestRunner
    unittest.main(
        verbosity=2,
        testRunner=ColourTextTestRunner
    )
