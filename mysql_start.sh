#!/bin/bash

doCommand="mysql -uroot --socket=${MYSQL_HOME}/mysqld-${PORT}.sock"

sed -i "s%port=3306%port=${PORT}%g" ${MYSQL_HOME}/my.cnf
sed -i "s%socket=.*%socket=${MYSQL_HOME}\/mysqld-${PORT}.sock%g" ${MYSQL_HOME}/my.cnf
#sed -i "s%datadir=.*%datadir=${MYSQL_HOME}\/data%g" ${MYSQL_HOME}/my.cnf
#sed -i "s%basedir=.*%basedir=${MYSQL_HOME}%g" ${MYSQL_HOME}/my.cnf
#sed -i "s%log-bin=.*%log-bin=${MYSQL_HOME}\/mylog%g" ${MYSQL_HOME}/my.cnf
sed -i "s%pid-file=.*%pid-file=${MYSQL_HOME}\/mysql-${PORT}.pid%g" ${MYSQL_HOME}/my.cnf
sed -i "s%log-error=.*%log-error=${MYSQL_HOME}\/mysql-${PORT}.err%g" ${MYSQL_HOME}/my.cnf

echo "====>modified server-id=${PORT}"
sed -i "s%server-id=1%server-id=${PORT}%g" ${MYSQL_HOME}/my.cnf

/usr/sbin/mysqld --initialize-insecure --basedir=${MYSQL_HOME} --datadir=${MYSQL_HOME}/data --user=mysql 
/usr/sbin/mysqld --defaults-file=${MYSQL_HOME}/my.cnf --basedir=${MYSQL_HOME} --port=${PORT} --user=mysql &

doSql=true
while(true); do
  sleep 6s
  if $doSql; then
     echo "====>set mysql password for root."
     $doCommand -e "use mysql; UPDATE user SET authentication_string=PASSWORD('123456') where USER='root'; commit; FLUSH PRIVILEGES;"
     if [ "${START_MODE}" = "master" ]; then
       echo "====>start mysql master."
       $doCommand -p123456 -e "CREATE USER sync@'%.%.%.%' IDENTIFIED BY '123456';GRANT REPLICATION SLAVE ON *.* TO sync@'%.%.%.%' IDENTIFIED BY '123456'; FLUSH PRIVILEGES;"
       echo "====>create user sync on master."
     fi
     if [ "${START_MODE}" = "slave" ]; then
       echo "====>statr mysql slave."
       $doCommand -p123456 -e "CHANGE MASTER TO MASTER_HOST='${MASTER_HOST}', MASTER_USER='sync', MASTER_PASSWORD='123456',MASTER_PORT=${MASTER_PORT}, MASTER_CONNECT_RETRY=5; START SLAVE; FLUSH PRIVILEGES;" 
       
       sed -i "s%1%2%g" ${MYSQL_HOME}/data/auto.cnf 
       /usr/bin/mysqladmin --port=${PORT} -uroot -p123456 shutdown
       /usr/sbin/mysqld --defaults-file=${MYSQL_HOME}/my.cnf --basedir=${MYSQL_HOME} --port=${PORT} --user=mysql &
       echo "modified service-uuid and restart slave."
     fi
     doSql=false
  fi
done

