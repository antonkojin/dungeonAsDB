#!/usr/bin/env python3

import unittest
import requests
from requests import codes
from sys import argv as args
import sys

heroku = len(args) >= 2 and args[1] == 'heroku'
if heroku:
    sys.argv = args[:1] + args[2:]
host = 'https://progetto-db.herokuapp.com/' if heroku else 'http://localhost:8000/'
from os.path import dirname, realpath
init_db_script = 'heroku run db/heroku_init_db.py db/schema.sql db/data.sql db/functions.sql' if heroku else dirname(
        realpath(__file__)) + '/../db/docker_init_db.sh schema.sql functions.sql data.sql'
clean_db_script = 'heroku run db/heroku_init_db.py db/schema.sql db/data.sql' if heroku else dirname(
        realpath(__file__)) + '/../db/docker_init_db.sh schema.sql data.sql'


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
            subprocess.call(init_db_script, shell=True,
                            stdout=DEVNULL, stderr=subprocess.STDOUT)

    def tearDown(self):
        from os import devnull
        import subprocess
        with open(devnull, 'w') as DEVNULL:
            subprocess.call(clean_db_script, shell=True,
                            stdout=DEVNULL, stderr=subprocess.STDOUT)

    def test_signup(self):
        request_data = {
            'email': 'test@example.com',
            'nickname': 'test_nickname',
            'password': 'test_password'
        }
        response = requests.post(url('user'), data=request_data)
        self.assertEqual(
            response.status_code,
            codes.no_content
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
        expected_status_codes = [codes.created]
        data = {
            'name': 'test_character_name',
            'description': 'test_character_not_very_long_description',
            'strength': 18,
            'intellect': 10,
            'dexterity': 3,
            'constitution': 17
        }
        response = requests.post(url('character'), auth=auth, data=data)
        self.assertIn(
            response.status_code,
            expected_status_codes
        )

    def test_cant_create_another_character(self):
        self.test_create_character()
        data = {
            'name': 'test_character_name',
            'description': 'test_character_not_very_long_description',
            'strength': 18,
            'intellect': 18,
            'dexterity': 18,
            'constitution': 18
        }
        another_data = {
            'name': 'test_character_name2',
            'description': 'test_character_not_very_long_description2',
            'strength': 12,
            'intellect': 9,
            'dexterity': 8,
            'constitution': 10
        }
        requests.post(url('character'), auth=auth, data=data)
        response = requests.post(
            url('character'), auth=auth, data=another_data)
        self.assertEqual(
            response.status_code,
            codes.conflict
        )

    def test_cant_create_wrong_character(self):
        self.test_signup()
        data = {
            'name': 'test_character_name',
            'description': 'test_character_not_very_long_description',
            'strength': 20,
            'intellect': 3,
            'dexterity': 19,
            'constitution': 2
        }
        response = requests.post(url('character'), auth=auth, data=data)
        self.assertEqual(
            response.status_code,
            codes.bad_request
        )

    def test_start_dungeon(self):
        self.test_create_character()
        expected_status_codes = [codes.created, codes.conflict]
        response = requests.post(url('dungeon'), auth=auth)
        self.assertIn(
            response.status_code,
            expected_status_codes
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
        character = response_json['character']
        self.assertIn('name', character)
        self.assertIn('description', character)
        self.assertIn('attack_item', character)
        self.assertIn('defence_item', character)
        self.assertIn('bag', character)
        bag = character['bag']
        self.assertTrue(len(bag) >= 2)
        item = bag[0]
        self.assertIn('id', item)
        self.assertIn('name', item)
        self.assertIn('description', item)
        self.assertIn('attack', item)
        self.assertIn('defence', item)
        self.assertIn('wisdom', item)
        self.assertIn('hit_points', item)
        self.assertIn('category', item)
        self.assertIn('room', response_json)
        room = response_json['room']
        self.assertIn('description', room)
        self.assertIn('items', room)
        self.assertIn('enemies', room)
        self.assertIn('gates', room)

    @unittest.skip('')
    def test_cant_start_another_dungeon(self):
        requests.post(url('dungeon'), auth=auth)
        response = requests.post(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code,
            codes.conflict
        )

    @unittest.skip('')
    def test_terminate_dungeon(self):
        requests.post(url('dungeon'), auth=auth)
        response = requests.post(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code,
            codes.conflict
        )
        response = requests.delete(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code,
            codes.ok
        )
        response = requests.post(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code,
            codes.created
        )

    @unittest.skip('')
    def test_take_item_from_room(self):
        response = requests.get(url('dungeon'), auth=auth)
        items = response.json()['room']['items']
        if len(items) == 0:
            self.skipTest('can\'t test, there\'s no items here')
        response = requests.put(
            url('dungeon/item/{item}'.format(item=item)),
            auth=auth
        )
        self.assertEqual(
            response.status_code,
            codes.no_content
        )

    @unittest.skip('')
    def test_follow_gate_to_other_room(self):
        response = requests.get(url('dungeon'), auth=auth)
        previous_room = response.json()['room']
        gate = previous_room['gates'][0]['id']
        response = requests.get(
            url('dungeon/gate/{gate}'.format(gate=gate)),
            auth=auth
        )
        self.assertEqual(
            response.status_code,
            codes.ok
        )
        self.assertNotEqual(
            response.json()['room'],
            previous_room
        )

    @unittest.skip('')
    def test_use_consumable_item(self):
        response = requests.get(url('dungeon'), auth=auth)
        character = response.json()['character']
        items = character['bag']
        consumable_items = [
            item
            for item in items
            if item['type'] == 'consumable'
        ]
        if len(consumable_items) == 0:
            self.skipTest('can\'t test, don\'t have consumable items')
        item = consumable_items[0]
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


if __name__ == '__main__':
    from colour_runner.runner import ColourTextTestRunner
    unittest.main(
        verbosity=2,
        testRunner=ColourTextTestRunner
    )
