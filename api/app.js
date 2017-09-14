const express = require('express')
const cors = require('cors')
const helmet = require('helmet')
const basicAuth = require('basic-auth')
const passwordHash = require('password-hash');
const pgp = require('pg-promise')(/* init options */)

const app = express()
const db = pgp(process.env.DATABASE_URL)
app.use(helmet());
app.use(cors());

/*
// CORS support
app.use(function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
  next();
});
*/

function checkPassword(user, password) {
    db.one('SELECT password_hash FROM users WHERE email = $1', user)
    .then(data => {
        return passwordHash.verify(password, data.password_hash);
    })
    .catch(error => {
        return false;
    });
};

app.use(function(req, res, next) {
    if (req.method == 'POST' && req.path == '/user') {
       return next(); 
    }
    const auth = basicAuth(req)
    if ( !auth || !checkPassword(auth.name, auth.password) ) {
        res.status(401).set('WWW-Authenticate', 'Basic');
    }
    req.auth = {
        user: auth.name,
    };
    return next();
});


app.get('/', function (req, res) {
  res.send('Hello World!')
})

app.listen(5000)


