#!/usr/bin/env python3

import psycopg2 as db
from os import getenv
from psycopg2 import Error, Warning
from sys import argv as args

db_url = getenv('DATABASE_URL')
with db.connect(db_url) as connection:
    connection.autocommit = True
    with connection.cursor() as cursor:
        for file in args[1:]:
            with open(file, 'r') as sql:
                try:
                    cursor.execute(sql.read())
                except db.Error as e:
                    print(e)
                except db.Warning as w:
                    print(w)
