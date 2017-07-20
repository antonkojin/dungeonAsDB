#!/usr/bin/env python3

import unittest
import requests

def url(path):
    return "http://localhost:8000/" + path

auth = (
    'test@example.com',
    'test_password'
)

class TestDungeonAsDB(unittest.TestCase):
    def test_signup(self):
        expected_status_codes = [204, 409]
        request_data = {
            'email':'test@example.com',
            'nickname': 'test_nickname',
            'password': 'test_password'
        }
        response = requests.post(url('user'), data=request_data)
        self.assertIn(
            response.status_code, 
            expected_status_codes
        )

    def test_login(self):
        expected_status_code = 200
        response = requests.get(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code, 
            expected_status_code
        )

    def test_cant_login_with_wrong_password(self):
        expected_status_code = 401
        auth = (
            'test@example.com',
            'test_password_wrong'
        )
        response = requests.get(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code, 
            expected_status_code
        )

    @unittest.skip('')
    def test_create_character(self):
        expected_status_codes = [201, 409]
        data = {
            'name': 'test_character_name',
            'description': 'test_character_not_very_long_description',
            'strength': 18,
            'intellect': 18,
            'dexterity': 18,
            'constitution': 18
        }
        response = requests.post(url('character'), auth=auth, data=data)
        self.assertIn(
            response.status_code, 
            expected_status_codes
        )

    @unittest.skip('')
    def test_cant_create_another_character(self):
        expected_status_code = 409
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
        response = requests.post(url('character'), auth=auth, data=another_data)
        self.assertEqual(
            response.status_code, 
            expected_status_code
        )

    @unittest.skip('')
    def test_start_dungeon(self):
        expected_status_codes = [201, 409]
        response = requests.post(url('dungeon'), auth=auth)
        self.assertIn(
            response.status_code, 
            expected_status_codes
        )
        
    @unittest.skip('')
    def test_cant_start_another_dungeon(self):
        expected_status_code = 409
        requests.post(url('dungeon'), auth=auth)
        response = requests.post(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code, 
            expected_status_code
        )

    @unittest.skip('')
    def test_terminate_dungeon(self):
        requests.post(url('dungeon'), auth=auth)
        response = requests.post(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code, 
            409
        )
        response = requests.delete(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code, 
            200
        )
        response = requests.post(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code, 
            201
        )

    @unittest.skip('')
    def test_dungeon_status(self):
        expected_status_code = 200
        requests.get(url('dungeon'), auth=auth)
        response = requests.post(url('dungeon'), auth=auth)
        self.assertEqual(
            response.status_code,
            expected_status_code
        )
        response_json = response.json()
        self.assertIn('room', response_json)
        room = response_json['room']
        self.assertIn('description', room)
        self.assertIn('items', room)
        self.assertIn('enemies', room)
        self.assertIn('gates', room)
        self.assertIn('character', response_json)
        character = response_json['character']
        self.assertIn('bag', character)
        

if __name__ == '__main__':
    unittest.main(verbosity=2)

