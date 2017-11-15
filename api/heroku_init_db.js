const pgp = require('pg-promise')();
const fs = require('fs');

pgp.pg.defaults.ssl = true;
const db = pgp(process.env.DATABASE_URL);

const files = process.argv.slice(2);

fs.readFile('../db/schema.sql', 'utf8', (error, data) => {
    db.none(data)
        .then(() => {
            console.log('done loading schema');
            fs.readFile('../db/functions.sql', 'utf8', (error, data) => {
                db.none(data)
                    .then(() => {
                        console.log('done loading functions');
                        fs.readFile('../db/data.sql', 'utf8', (error, data) => {
                            db.none(data)
                                .then(() => {
                                    console.log('done loading data');
                                })
                                .catch(error => {
                                    console.log(error);
                                });
                        });
                    })
                    .catch(error => {
                        console.log(error);
                    });
            });
        })
        .catch(error => {
            console.log(error);
        });
});
