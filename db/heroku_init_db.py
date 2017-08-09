#!/usr/bin/env python3

import psycopg2 as db
from os import getenv
from sys import argv as args

db_url = getenv('DATABASE_URL')
with db.connect(db_url) as connection:
    with connection.cursor() as cursor:
        for file in args[1:]:
            with open(file, 'r') as sql:
                try:
                    cursor.execute(sql.read())
                except db.StandardError as e:
                    print(e)
