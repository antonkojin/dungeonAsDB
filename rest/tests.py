#!/usr/bin/env python3

import json
import requests

def url(path):
    return "http://localhost:8000/" + path

import unittest

class TestUserSignup(unittest.TestCase):

    def test_signup(self):
        data = {
            'email':'test@example.com',
            'nickname': 'test_nickname',
            'password': 'test_password'
        }
        response = requests.post(url("user"), data=data)
        expected = {
            'email':'test@example.com',
            'nickname': 'test_nickname'
        }
        self.assertEquals(response.status_code, 201)
        self.assertEqual(response.json(), expected)
 

if __name__ == '__main__':
    unittest.main()
 
