#!/bin/bash
export $(xargs < .env)

echo "GENERATE KEY FOR APP"
docker exec $APP_NAME php artisan key:generate
echo "WAIT TO CONNECT..."
sleep 15

docker exec $READER_DB_HOST sh -c 'export MYSQL_PWD=$MYSQL_PASSWORD; mysql -u root -e ";"'

until docker exec $WRITER_DB_HOST sh -c 'export MYSQL_PWD=$MYSQL_PASSWORD; mysql -u root -e ";"'
do
    echo "Waiting for mysql_master database connection..."
    sleep 4
done

priv_stmt='CREATE USER "'$READER_DB_USERNAME'"@"%" IDENTIFIED BY "'$READER_DB_PASSWORD'"; GRANT REPLICATION SLAVE ON *.* TO "'$READER_DB_USERNAME'"@"%"; FLUSH PRIVILEGES;'
one='export MYSQL_PWD=$MYSQL_PASSWORD; '
two=$one"mysql -u root -e '$priv_stmt'"
docker exec $WRITER_DB_HOST sh -c "$two"

until docker exec $READER_DB_HOST sh -c 'export MYSQL_PWD=$MYSQL_PASSWORD; mysql -u root -e ";"'
do
    echo "Waiting for mysql_slave database connection..."
    sleep 4
done

MS_STATUS=`docker exec $WRITER_DB_HOST sh -c 'export MYSQL_PWD=$MYSQL_PASSWORD; mysql -u root -e "SHOW MASTER STATUS"'`
CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`
CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`
echo "$CURRENT_LOG"
echo "$CURRENT_POS"

three='CHANGE MASTER TO MASTER_HOST="'$WRITER_DB_HOST'",MASTER_USER="'$READER_DB_USERNAME'",MASTER_PASSWORD="'$READER_DB_PASSWORD'",MASTER_LOG_FILE="'$CURRENT_LOG'",MASTER_LOG_POS='$CURRENT_POS'; START SLAVE;'
echo "$three"
five='export MYSQL_PWD=$MYSQL_PASSWORD; ' 
six=$five"mysql -u root -e '$three'"

docker exec $READER_DB_HOST sh -c "$six"

docker exec $READER_DB_HOST sh -c 'export MYSQL_PWD=$MYSQL_PASSWORD; mysql -u root -e "SHOW SLAVE STATUS \G"'

echo "WAIT TO MIGRATE..."
sleep 15

docker exec $APP_NAME php artisan migrate:fresh --seed