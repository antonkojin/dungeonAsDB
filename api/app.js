const express = require('express')
const morgan = require('morgan');
const bodyParser = require('body-parser');
const cors = require('cors')
const helmet = require('helmet')
const basicAuth = require('basic-auth')
const passwordHash = require('password-hash');
const pgp = require('pg-promise')(/* init options */)
const winston = require('winston')
const https = require('https');
const fs = require('fs');

const app = express()
const db = pgp(process.env.DATABASE_URL)
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
// app.all('*', redirectHttpToHttps);
app.use(verifyAuth);
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

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
        winston.warning(error);
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

function redirectHttpToHttps(req, res, next){
  if(req.secure){
    return next();
  };
  res.redirect('https://' + req.hostname + req.url);
};

function verifyAuth(req, res, next) {
    let authenticateResponse = function() {
        res.status(401).set('WWW-Authenticate', 'Basic').send();
    };
    if (req.method == 'POST' && req.path == '/user') {
       return next();
    }
    const auth = basicAuth(req);
    if (!auth) {
        authenticateResponse();
    }
    winston.info(auth);
    checkPassword(auth.name, auth.pass)
        .then(verified => {
            if (verified) {
                req.auth = { user: auth.name };
                next();
            }
            else {
                authenticateResponse();
            }
        });
};

function checkPassword(user, password) {
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

const credentials = {
    key: fs.readFileSync('ssl/server.key', 'utf8'),
    cert: fs.readFileSync('ssl/server.crt', 'utf8')
};
app.listen(80);
https.createServer(credentials, app).listen(443);

