#!/usr/bin/env bash

psql \
    --echo-errors \
    --dbname=dungeon_as_db \
    --file=/code/schema.sql \
    --username=dungeon_as_db_superuser

