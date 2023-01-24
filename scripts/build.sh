#!/bin/bash

priv_stmt='show databases; CREATE USER "'$READER_DB_USERNAME'"@"%" IDENTIFIED BY "'$READER_DB_PASSWORD'"; GRANT REPLICATION SLAVE ON *.* TO "'$READER_DB_USERNAME'"@"%"; FLUSH PRIVILEGES;'

one='export MYSQL_PWD=$MYSQL_PASSWORD; '
two=$one"mysql -u root -e '$priv_stmt'"
echo "$two"
