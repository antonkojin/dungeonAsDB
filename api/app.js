const express = require('express')
const morgan = require('morgan');
const bodyParser = require('body-parser');
const cors = require('cors')
const helmet = require('helmet')
const basicAuth = require('basic-auth')
const passwordHash = require('password-hash');
const pgp = require('pg-promise')(/* init options */)
const winston = require('winston')
const util = require('util');

const app = express()
const db = pgp(process.env.DATABASE_URL)
app.use(morgan('dev'));
app.use(helmet());
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

const checkPassword = (user, password) => {
    return db.one('SELECT password_hash FROM users WHERE email = $1', user)
        .then(data => {
            return passwordHash.verify(password, data.password_hash);
        })
        .catch(error => {
            if (error instanceof pgp.errors.QueryResultError && error.code === pgp.errors.queryResultErrorCode.noData) {
                return false;
            }
            winston.error(error);
            res.sendStatus(500);
        });
};

const verifyAuth = function (req, res, next) {
    if (req.method == 'POST' && req.path == '/user') {
       return next();
    }
    const auth = basicAuth(req);
    winston.info(auth);
    if (!auth) {
        return res.status(401).set('WWW-Authenticate', 'Basic').send();
    }
    checkPassword(auth.name, auth.pass)
        .then(verified => {
            if (!verified) {
                res.status(401).set('WWW-Authenticate', 'Basic').send();
            }
            else {
                req.auth = { user: auth.name };
                next();
            }
        });
};
app.use(verifyAuth);


app.post('/user', (req, res) => {
    winston.info(req.body);
    hashedPassword = passwordHash.generate(req.body.password);
    db.none(
        'INSERT INTO users(email, nickname, password_hash) VALUES (${email}, ${nickname}, ${password_hash})',
        {
            email: req.body.email,
            nickname: req.body.nickname,
            password_hash: hashedPassword
        }
    ).then(() => {
        res.sendStatus(204);
    }).catch(error => {
        winston.error(error);
        res.sendStatus(409);
    });
});

app.get('/user', (req, res) => {
    db.one(
        'SELECT email, nickname FROM users WHERE email = $1',
        req.auth.user
    )
        .then(user => {
            res.json(user);
        })
        .catch(error => {
            winston.error(error);
            res.sendStatus(500);
        });
});

app.delete('/user', (req, res) => {
    db.func('delete_user', req.auth.user)
        .then(() => {
            res.sendStatus(200);
        })
        .catch(error => {
            winston.error(error);
            res.sendStatus(500);
        });
});

app.get('/dices', (req, res) => {
    db.func('get_character_dices', req.auth.user, pgp.queryResult.many)
        .then(dices => {
            res.status(200).json(dices);
        })
        .catch(error => {
            if (error instanceof pgp.errors.QueryResultError
                && error.code === pgp.errors.queryResultErrorCode.noData
            ) {
                res.sendStatus(404);
            } else {
                winston.error(error);
                res.sendStatus(500);
            }
        });
});

app.post('/character', (req, res) => {
    winston.info(req.body);
    db.func('create_character', [
        req.body.name,
        req.body.description,
        req.body.strength,
        req.body.intellect,
        req.body.dexterity,
        req.body.constitution,
        req.auth.user
    ])
        .then(() => {
            res.sendStatus(201);
        })
        .catch(error => {
            winston.error(util.inspect(error));
            if (error.code == 23502) { // not_null_violation
                res.sendStatus(400);
            } else if (error.code == 23505) { // unique_violation
                res.sendStatus(409);
            } else if (error.code === 'P0001') { // raised exception
                res.sendStatus(400);
            } else {
                res.sendStatus(500);
            }
        });
});

app.post('/dungeon', (req, res) => {
    db.func('create_dungeon', req.auth.user)
        .then( () => {
            res.sendStatus(201);
        })
        .catch( error => {
            if (error.code == 23505) { // unique_violation
                res.sendStatus(409);
            }
        });
});

app.get('/dungeon', (req, res) => {
    db.tx(t => {
        return t.batch([
            db.func('get_character', req.auth.user).then(d => d[0]),
            db.func('get_character_items', req.auth.user),
            db.func('get_room', req.auth.user).then(d => d[0]),
            db.func('get_room_items', req.auth.user),
            db.func('get_room_enemies', req.auth.user),
            db.func('get_room_gates', req.auth.user)
        ]);
    })
        .then(data => {
            const dungeonStatus = {};
            dungeonStatus.character = data[0];
            dungeonStatus.character.bag = data[1];
            dungeonStatus.room = data[2];
            dungeonStatus.room.items = data[3];
            dungeonStatus.room.enemies = data[4];
            dungeonStatus.room.gates = data[5];
            res.json(dungeonStatus);
        })
        .catch(error => {
            winston.error(util.inspect(error));
        });
});

app.delete('/dungeon', (req, res) => {
    db.func('end_dungeon', req.auth.user)
        .then(() => {
            res.sendStatus(200);
        })
        .catch(error => {
            winston.error(util.inspect(error));
        });
});

app.get('/dungeon/gate/:gateId', (req, res) => {
    db.func('follow_gate', [req.auth.user, req.params.gateId])
        .then(() => {
            res.sendStatus(200);
        })
        .catch(error => {
            winston.error(util.inspect(error));
        });
});

app.post('/dungeon/enemy/:enemyId', (req, res) => {
    db.func('fight_enemy', [req.auth.user, req.params.enemyId])
        .then(data => {
            winston.info(util.inspect(data));
            res.json(data);
        })
        .catch(error => {
            winston.error(util.inspect(error));
        });
});

app.post('/dungeon/item/:itemId', (req, res) => {
    db.func('take_item', [req.auth.user, req.params.itemId])
        .then(([data]) => {
            const id = {'id': data.take_item};
            winston.info(util.inspect(id));
            res.json(id);
        })
        .catch(error => {
            winston.error(util.inspect(error));
        });
});

app.post('/dungeon/bag/:itemId', (req, res) => {
    db.func('use_item', [req.auth.user, req.params.itemId])
        .then(() => {
            res.sendStatus(200);
        })
        .catch(error => {
            winston.error(util.inspect(error));
        });
});

app.get('/dungeon/search', (req, res) => {
    db.func('room_search', req.auth.user)
        .then(([data]) => {
            winston.info(`search: ${util.inspect(data)}`);
            res.json(data);
        })
        .catch(error => {
            if (error.code === 'P0001') {
                res.sendStatus(418) // I'm a teapot HTTP response code
            } else {
                winston.error(util.inspect(error));
                res.sendStatus(500);
            }
        });
});

app.listen(process.env.PORT)
