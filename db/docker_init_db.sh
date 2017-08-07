#!/usr/bin/env bash

docker-compose exec db \
    psql \
        --echo-errors \
        --dbname=dungeon_as_db \
        --file=/code/schema.sql \
        --username=dungeon_as_db_superuser && \
docker-compose exec db \
    psql \
        --echo-errors \
        --dbname=dungeon_as_db \
        --file=/code/data.sql \
        --username=dungeon_as_db_superuser

docker-compose exec db \
    psql \
        --echo-errors \
        --dbname=dungeon_as_db \
        --file=/code/functions.sql \
        --username=dungeon_as_db_superuser

