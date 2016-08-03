# docker-mysql-ms

构建主从复制模式的mysql镜像

使用了 Percona-Server-5.6.24-rel72.2-Linux.x86_64 版本，构建docker镜像。

运行命令：
## master run:
docker run -d --net=host -p 39008:39008 -v /aifs01/mysqldata:/percona_volumn/data -e "PORT=39008" -e "START_MODE=master" 10.1.245.4:5000/mysql-replication:5.6.24

## slave run:
docker run -d --net=host -p 39009:39009 -v /aifs01/mysqldata:/percona_volumn/data -e "PORT=39009" -e "START_MODE=slave" -e "SLAVE_ID=2" -e "MASTER_HOST=10.1.245.225" -e "MASTER_PORT=39008" 10.1.245.4:5000/mysql-replication:5.6.24

