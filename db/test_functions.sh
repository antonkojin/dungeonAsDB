#!/bin/sh

./docker_init_db.sh functions.sql && \
curl -u test@example.com:test_password localhost:8000/dices -I
