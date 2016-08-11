#!/bin/bash

doFlag=true
lockFile=/percona/mysqld-${PORT}.sock.lock
doCommand="mysql -uroot --socket=${MYSQL_HOME}/mysqld-${PORT}.sock"

sed -i "s%port=3306%port=${PORT}%g" ${MYSQL_HOME}/my.cnf
sed -i "s%socket=.*%socket=${MYSQL_HOME}\/mysqld-${PORT}.sock%g" ${MYSQL_HOME}/my.cnf
sed -i "s%pid-file=.*%pid-file=${MYSQL_HOME}\/mysql-${PORT}.pid%g" ${MYSQL_HOME}/my.cnf
sed -i "s%log-error=.*%log-error=${MYSQL_HOME}\/mysql-${PORT}.err%g" ${MYSQL_HOME}/my.cnf
sed -i "s%server-id=1%server-id=${PORT}%g" ${MYSQL_HOME}/my.cnf

if [ ! -f "$lockFile" ]; then
    echo "++++++++++ to delete $lockFile  ++++++++++"
    rm -rf $lockFile
fi

if [ ! -f "/percona/data/auto.cnf" ]; then
    /usr/sbin/mysqld --initialize-insecure --basedir=${MYSQL_HOME} --datadir=${MYSQL_HOME}/data --user=mysql 
    echo "++++++++++ create mysqldb ++++++++++"
fi

/usr/sbin/mysqld --defaults-file=${MYSQL_HOME}/my.cnf --basedir=${MYSQL_HOME} --port=${PORT} --user=mysql &

while(true); do
   sleep 6s
   if $doFlag; then     
     echo "====>set mysql password for root."
     $doCommand -e "use mysql; UPDATE user SET authentication_string=PASSWORD('123456') where USER='root'; commit; FLUSH PRIVILEGES;"
     if [ "${START_MODE}" = "master" ]; then
       echo "====>start mysql master."
       $doCommand -p123456 -e "CREATE USER sync@'%.%.%.%' IDENTIFIED BY '123456';GRANT REPLICATION SLAVE ON *.* TO sync@'%.%.%.%' IDENTIFIED BY '123456'; FLUSH PRIVILEGES;"
       echo "====>create user sync on master."
       $doCommand -p123456 -e "CREATE USER ${DB_ROOT_NAME}@'%.%.%.%' IDENTIFIED BY '${DB_ROOT_PASSWORD}';GRANT ALL PRIVILEGES ON *.* TO ${DB_ROOT_NAME}@'%.%.%.%' IDENTIFIED BY '${DB_ROOT_PASSWORD}' WITH GRANT OPTION;FLUSH PRIVILEGES;"
     fi
     if [ "${START_MODE}" = "slave" ]; then
       echo "====>statr mysql slave."
       $doCommand -p123456 -e "CHANGE MASTER TO MASTER_HOST='${MASTER_HOST}', MASTER_USER='sync', MASTER_PASSWORD='123456',MASTER_PORT=${MASTER_PORT}, MASTER_CONNECT_RETRY=5; START SLAVE; FLUSH PRIVILEGES;" 
       
       sed -i "s%1%2%g" ${MYSQL_HOME}/data/auto.cnf 
       /usr/bin/mysqladmin --port=${PORT} -uroot -p123456 shutdown
       /usr/sbin/mysqld --defaults-file=${MYSQL_HOME}/my.cnf --basedir=${MYSQL_HOME} --port=${PORT} --user=mysql &
       echo "modified service-uuid and restart slave."
    fi
    doFlag=false
  fi
done

