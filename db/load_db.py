#!/usr/bin/env python3

import psycopg2 as db
from os import getenv
from sys import argv as args

db_url = getenv('DATABASE_URL')
with open(args[1], 'r') as sql:
    with db.connect(db_url) as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql.read())
