# docker-mysql-ms

构建主从复制模式的mysql镜像

使用了 Percona-Server-5.7.13-6-re3d58bb-el7-x86_64-bundle 版本，构建docker镜像。
可以从官网https://www.percona.com/downloads/Percona-Server-5.7/LATEST/ ,下载Percona-Server-5.7.13-6-re3d58bb-el7-x86_64-bundle.tar 。

需要在宿主机创建挂载目录：/aifs01/dbdata ,并授予读写权限。

## docker build
docker build -t 10.1.245.4:5000/mysql-replication-20:5.7.13 .

## docker run command：
 master run:
docker run --name image-test-master -d --net=host -p 7777:7777  -v /aifs01/dbdata/7777:/percona/data --cpuset-cpus=0 --memory-reservation 1G -e "PORT=7777" -e "START_MODE=master" -e "DB_ROOT_NAME=rootusr" -e "DB_ROOT_PASSWORD=123456" -e "DB_WHITE_LIST=10.1.*.*,192.168.*.*,%.%.%.%" -e "BANDWIDTH=4" -e "SQL_AUDIT=on" -e "SYNC_STRATEGY=semisynchronous" -e "SERVER_ID=1" 10.1.245.4:5000/mysql-replication-20:5.7.13

 slave run:
docker run --name image-test-slave -d --net=host -p 8888:8888  -v /aifs01/dbdata/8888:/percona/data --cpuset-cpus=1 --memory-reservation 1G -e "PORT=8888" -e "START_MODE=slave" -e "DB_ROOT_NAME=rootusr" -e "DB_ROOT_PASSWORD=123456" -e "DB_WHITE_LIST=10.1.*.*,192.168.*.*,%.%.%.%" -e "BANDWIDTH=4" -e "MASTER_HOST=10.1.245.226" -e "MASTER_PORT=7777"    -e "SQL_AUDIT=on" -e "SYNC_STRATEGY=semisynchronous" -e "SERVER_ID=2" 10.1.245.4:5000/mysql-replication-20:5.7.13

## failover command example
docker exec -id bakmasterid /switch.sh 10.1.1.1 9999 master master_switch
docker exec -id slaveid /switch.sh 10.1.1.1 9999 slave slave_switch
docker exec -id masterid /switch.sh 10.1.1.1 9999 bakmaster bakmaster_switch
10.1.1.1 is the new master ip, 9999 is the new master port.
