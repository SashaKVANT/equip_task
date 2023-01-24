# _Equip-app documentation_
- clone repo to your local machine
- running application consists of services: __Laravel, Nginx, MySQL__
- In addition to the basic services, __Prometheus - Grafana__ monitoring is provided 

---
In your .env file define the empty variables:
```
APP_NAME=laravel
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8000

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

WRITER_DB_CONNECTION=mysql
WRITER_DB_HOST=
WRITER_DB_PORT=3306
WRITER_DB_DATABASE=
WRITER_DB_USERNAME=
WRITER_DB_PASSWORD=

READER_DB_CONNECTION=mysql
READER_DB_HOST=
READER_DB_PORT=3306
READER_DB_DATABASE=
READER_DB_USERNAME=
READER_DB_PASSWORD=
```
__WRITER_DB_HOST__ and __READER_DB_HOST__ define the name for your __mysql:8.0__ containers

---

In ```/docker-compose/mysql``` stored __.cnf__ files for __WRITER_DB__ and __READER_DB__

__db_reader.cnf__
```
[mysqld]
skip-name-resolve
default_authentication_plugin = mysql_native_password

server-id = 2
log_bin = 1
log_bin = mysql-bin
replicate_do_db = <READER_DB_DATABASE>
replicate-rewrite-db="<WRITER_DB_DATABASE>-><READER_DB_DATABASE>"
```
Instead of __<READER_DB_DATABASE>__ and __<WRITER_DB_DATABASE>__  enter this values from your .env file

For example, in .env file :
```
WRITER_DB_DATABASE=wr_db
READER_DB_DATABASE=re_db
```
So, __db_reader.cnf__ should look like :
```
[mysqld]
skip-name-resolve
default_authentication_plugin = mysql_native_password

server-id = 2
log_bin = 1
log_bin = mysql-bin
replicate_do_db = re_db
replicate-rewrite-db="wr_db->re_db"
```

By analogy with __db_reader.cnf__, fill in the __db_writer.cnf__ :
```
[mysqld]
skip-name-resolve
default_authentication_plugin = mysql_native_password

server-id = 1
log_bin = mysql-bin
binlog_format = ROW
binlog_do_db = <WRITER_DB_DATABASE>
```

---
Build a Docker image of the __app service__ by command (in root directory of project)
```
$ docker-compose build
```
The built image is based on __php:8.1.0-fpm__ image. I added __npm__ and __composer:2.1.8__ to this image (image name - equip)

---

When the image is built, __run__ the containers with the command
```
$ docker-compose up -d
```
__Check__ that containers are healthy by command
```
$ docker ps
```
If containers are healthy let's move on to main script of the app


---
__test-script._sh___:

Script consists of three main parts:

- generate app key: ```artisan key:generate```
- connect to __WRITER_DB__ and __READER_DB__ and configuration of __master&rarr;slave__ replication
- setup migrations: ```artisan migrate:fresh --seed``` 

All commands are executed in running containers using the ```docker exec``` construction

Before and after configuration of master-slave replication the ```sleep``` command is used 

Let's start the script:
```
$ sh test-script.sh
```
In output you can see __SLAVE STATUS__ of __READER_DB_HOST__

---
Next, go to [localhost:8000](locahost:8000)

You can delete, insert, or mark entries as completed!

![complet](/assets/complete)

To check __http responses__ status execute:
```
$ docker logs <your nginx container name>
```
---
To shut down the application and delete volumes, run commands:
```
$ docker-compose down
$ docker volume prune
```
The commands above __MUST BE EXECUTED__ if you want to restart the application 

---
__Full list of commands for start__:
- change __.env__
- change __.cnf__

```
$ docker-compose build
$ docker-compose up -d
$ sh test-script.sh
```
__For restart__: 
```
$ docker-compose down
$ docker volume prune
```

---
_Monitoring with Grafana - Prometheus - Node_expoter_

In ```docker-compose.yml``` additionally defined three containers:
- grafana - to display and create dashboards
- prometheus - for storing and managing metrics
- nodeexporter - metrics generator for node
  
When your containers are up, go to [localhost:9090](locahost:9090)

You will be taken to the start page of __prometheus__
By clicking on the search icon to the right of the search bar, you can display the metrics that are generated for __prometheus__ by __nodeexporter__

If you want to create a dashboard for visualize by Grafana, copy code of metrics, for example : ```promhttp_metric_handler_requests_total{code="200", instance="localhost:9090", job="prometheus"}```

If you want to see in dashboard __total_http_requests_500__:
- go to [localhost:3000](locahost:3000)
- login in Grafana
- Dashboards&rarr;Import&rarr;Upload JSON file
- Insert or upload __dashboard.json__ located at 
 ```./docker-compose/grafana/dashboards```

---

Configuration files and dashboards

- __nginx.conf__ located at ```./docker-compose/nginx/nginx.conf```
- __db_writer.cnf__ and __db_reader.cnf__ located at 
 ```./docker-compose/mysql/```
- __prometheus.yml__ located at ```./docker-compose/prometheus/```
- __dashboard.json__ located at 
 ```./docker-compose/grafana/dashboards```
- __datasource.yml__ located at
 ```./docker-compose/grafana/datasources```