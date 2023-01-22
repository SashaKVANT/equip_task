#!/bin/bash
export $(xargs < .env)

echo "Waiting for mysql_master database connection..."
echo "export ${WRITER_DB_PASSWORD}; mysql -u root -e "
echo "export MYSQL_PWD=111; mysql -u root -e "
read_pass="$WRITER_DB_PASSWORD"
echo "$WRITER_DB_PASSWORD"

# docker exec -it equip_db_writer sh -c 'mysql -u "root" -p="$WRITER_DB_PASSWORD"'
docker exec equip_db_writer sh -c 'export MYSQL_PWD="1q1q1q1q"; mysql -u wr_db_user -e ";"'