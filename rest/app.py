from flask import Flask, jsonify, request
import psycopg2 as db
import psycopg2.errorcodes
from flask_httpauth import HTTPBasicAuth
from werkzeug.security import check_password_hash

app = Flask(__name__)
auth = HTTPBasicAuth()

import os
db_url = os.getenv('DATABASE_URL')

def get_pw(email):
    query = 'SELECT password_hash FROM users WHERE email = %s'
    arguments = (email, )
    with db.connect(db_url) as connection:
        with connection.cursor() as cursor:
            cursor.execute(query, arguments)
            result = cursor.fetchone()
    return result[0] if result is not None else None

@auth.verify_password
def verify_pw(username, password):
    db_pw = get_pw(username)
    return check_password_hash(db_pw, password)

@app.route('/user', methods=['POST'])
def signup():
    from werkzeug.security import generate_password_hash
    query = (
        'INSERT INTO users (email, nickname, password_hash) '
        'VALUES (%s, %s, %s)'
    ) 
    values = (
        request.form['email'],
        request.form['nickname'],
        generate_password_hash(request.form['password'])
    )
    with db.connect(db_url) as connection:
        with connection.cursor() as cursor:
            try:
                cursor.execute(query, values)
            except db.IntegrityError as e:
                app.logger.warning(e)
                return ('', 409)
    return ('', 204)

@app.route('/user', methods=['GET'])
@auth.login_required
def user():
    query = 'SELECT email, nickname FROM users WHERE email = %s'
    values = (auth.username(), )
    with db.connect(db_url) as connection:
        with connection.cursor() as cursor:
            cursor.execute(query, values)
            email, nickname = cursor.fetchone()
    return (
        jsonify({
            'email': email,
            'nickname': nickname
        }), 
        200
    )

@app.route('/character', methods=['POST'])
@auth.login_required
def create_character():
    email = auth.username()
    name = request.form['name']
    description = request.form['description']
    strength = request.form['strength']
    intellect = request.form['intellect']
    dexterity = request.form['dexterity']
    constitution = request.form['constitution']
    query = 'SELECT create_character(%s, %s, %s, %s, %s, %s, %s)'
    values = (
        name,
        description,
        strength,
        intellect,
        dexterity,
        constitution,
        email
    )
    with db.connect(db_url) as connection:
        with connection.cursor() as cursor:
            try:
                cursor.execute(query, values)
            except db.IntegrityError as e:
                app.logger.warning(e)
                if e.pgcode == db.errorcodes.CHECK_VIOLATION:
                    return ('', 400)
                elif e.pgcode == db.errorcodes.UNIQUE_VIOLATION:
                    return ('', 409)
                else:
                    raise e
                    

    return ('', 201)

@app.route('/dungeon', methods=['POST'])
@auth.login_required
def start_dungeon():
    email = auth.username()
    query = 'SELECT create_dungeon(%s)'
    with db.connect(db_url) as connection:
        with connection.cursor() as cursor:
            try:
                cursor.execute(query, (email, ))
            except db.IntegrityError as e:
                app.logger.warning(e)
                if e.pgcode == db.errorcodes.UNIQUE_VIOLATION:
                    return ('', 409)
                else:
                    raise e
    return ('', 201)

@app.route('/dungeon', methods=['GET'])
@auth.login_required
def dungeon_status():
    email = auth.username()
    query = 'SELECT dungeon_status(%s)'
    with db.connect(db_url) as connection:
        with connection.cursor() as cursor:
            cursor.execute(query, (email, ))
            dungeon_status = cursor.fetchAll()
    return (jsonify(dungeon_status), 200)

    


if __name__ == '__main__':
    from os import getenv
    app.run(
        debug=True, 
        host='0.0.0.0', 
        port=int(getenv('PORT', '5000'))
    )
