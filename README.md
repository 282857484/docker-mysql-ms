# docker-mysql-ms

构建主从复制模式的mysql镜像

使用了 Percona-Server-5.7.13-6-re3d58bb-el7-x86_64-bundle 版本，构建docker镜像。
可以从官网https://www.percona.com/downloads/Percona-Server-5.7/LATEST/ ,下载Percona-Server-5.7.13-6-re3d58bb-el7-x86_64-bundle.tar 。

需要在宿主机创建挂载目录：/aifs01/dbdata ,并授予读写权限。

运行命令：
## master run:
docker run -d --net=host -p 39008:39008 -v /aifs01/dbdata:/percona/data -e "PORT=39008" -e "START_MODE=master" 10.1.245.4:5000/mysql-replication:5.7.13

## slave run:
docker run -d --net=host -p 39009:39009 -v /aifs01/dbdata:/percona/data -e "PORT=39009" -e "START_MODE=slave" -e "MASTER_HOST=10.1.245.225" -e "MASTER_PORT=39008" 10.1.245.4:5000/mysql-replication:5.7.13

