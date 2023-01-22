#!/bin/bash

# docker-compose down -v
# rm -rf ./master/data/*
# rm -rf ./slave/data/*    #docker-compose stop with rm volumes     
docker volume prune 
# docker-compose build     #docker-compose build from master/slave .env list
export $(xargs < .env)     #export variables from .env file
echo "qwerty $WRITER_DB_PASSWORD"
echo "qwerty $READER_DB_USERNAME"

docker-compose up -d
docker-compose exec app php artisan key:generate # genenerate artisan app key

PARAMS="'MYSQL_PWD_MASTER=$WRITER_DB_PASSWORD MYSQL_READ_USER=$READER_DB_USERNAME MYSQL_DB_HOST=$WRITER_DB_HOST MYSQL_PWD_SLAVE=$READER_DB_PASSWORD '" 
DOCKER_EXEC_W="docker exec $WRITER_DB_HOST bash -c"

until docker exec equip_db_writer bash -c 'mysql -u root '
do
    echo "Waiting for mysql_master database connection..."   #enter master db and login from root..
    sleep 4
done

priv_stmt='GRANT REPLICATION SLAVE ON *.* TO "'$READER_DB_USERNAME'"@"%"; FLUSH PRIVILEGES;'
echo "$priv_stmt"
docker exec equip_db_writer bash -c $PARAMS"mysql -u root -e '$priv_stmt'"

until docker exec equip_db_reader bash -c $PARAMS'mysql -u root -e'
do
    echo "Waiting for mysql_slave database connection..."   #enter slave db and login from root..
    sleep 4
done

MY_COM='SHOW MASTER STATUS'
MS_STATUS=`docker exec equip_db_writer sh -c $PARAMS"mysql -u root -e '$MY_COM'"`
CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`
CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`

start_slave_stmt="CHANGE MASTER TO MASTER_HOST='"$WRITER_DB_HOST"',MASTER_USER='"$READER_DB_USERNAME"',MASTER_PASSWORD='"$READER_DB_PASSWORD"',MASTER_LOG_FILE='$CURRENT_LOG',MASTER_LOG_POS=$CURRENT_POS; START SLAVE;"
start_slave_cmd=$PARAMS'mysql -u root -e "'
start_slave_cmd+="$start_slave_stmt"
start_slave_cmd+='"'
echo $start_slave_cmd   
docker exec equip_db_reader sh -c "$start_slave_cmd"

docker exec equip_db_reader sh -c $PARAMS"mysql -u root -e 'SHOW SLAVE STATUS \G'"

docker-compose exec app php artisan migrate:fresh --seed #add migrations