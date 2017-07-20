#!/usr/bin/env python3

import requests

def url(path):
    return "http://localhost:8000/" + path

import unittest
class TestUserSignup(unittest.TestCase):

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
            expected_status_codes, 
            'bad status code'
        )

    def test_login(self):
        expected_status_codes = [200]
        auth = (
            'test@example.com',
            'test_password'
        )
        response = requests.get(url('dungeon'), auth=auth)
        self.assertIn(
            response.status_code, 
            expected_status_codes, 
            'bad status code'
        )

    def test_wrong_login(self):
        expected_status_codes = [401]
        auth = (
            'test@example.com',
            'test_password_wrong'
        )
        response = requests.get(url('dungeon'), auth=auth)
        self.assertIn(
            response.status_code, 
            expected_status_codes, 
            'bad status code'
        )

if __name__ == '__main__':
    unittest.main(verbosity=2)
 
