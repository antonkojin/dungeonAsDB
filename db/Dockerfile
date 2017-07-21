FROM postgres

COPY init_user_db.sql /docker-entrypoint-initdb.d/0-init_user_db.sql
COPY schema.sql /code/schema.sql
COPY psql_load_schema.sh /docker-entrypoint-initdb.d/1-init_tables.sh


