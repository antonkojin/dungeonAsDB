#!/usr/bin/env bash

# docker-compose up -d db;
docker-compose exec db \
	psql \
		--echo-errors \
		--dbname=dungeon_as_db \
		--file=/code/schema.sql \
		--username=dungeon_as_db_superuser ;
# docker-compose stop db;

