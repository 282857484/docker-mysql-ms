#!/bin/bash

doCommand="${MYSQL_HOME}/bin/mysql -uroot --socket=${MYSQL_HOME}/mysqld-${PORT}.sock"

sed -i "s%port=3306%port=${PORT}%g" ${MYSQL_HOME}/my.cnf
sed -i "s%socket=.*%socket=${MYSQL_HOME}\/mysqld-${PORT}.sock%g" ${MYSQL_HOME}/my.cnf
sed -i "s%datadir=.*%datadir=${MYSQL_HOME}\/data%g" ${MYSQL_HOME}/my.cnf
sed -i "s%basedir=.*%basedir=${MYSQL_HOME}%g" ${MYSQL_HOME}/my.cnf
sed -i "s%log-bin=.*%log-bin=${MYSQL_HOME}\/mylog%g" ${MYSQL_HOME}/my.cnf
sed -i "s%pid-file=.*%pid-file=${MYSQL_HOME}\/mysql-${PORT}.pid%g" ${MYSQL_HOME}/my.cnf
sed -i "s%log-error=.*%log-error=${MYSQL_HOME}\/mysql-${PORT}.err%g" ${MYSQL_HOME}/my.cnf

if [ "${START_MODE}" = "slave" ]; then
  echo "====>modified slave server-id=${SLAVE_ID}"
  sed -i "s%server-id=1%server-id=${SLAVE_ID}%g" ${MYSQL_HOME}/my.cnf
fi

${MYSQL_HOME}/bin/mysqld_safe --defaults-file=${MYSQL_HOME}/my.cnf --user=mysql &

doSql=true
while(true); do
  sleep 6s
  if $doSql; then
     echo "====>set mysql password for root."
     $doCommand -e "use mysql; UPDATE user SET Password=PASSWORD('123456') where USER='root'; commit; FLUSH PRIVILEGES;"
     if [ "${START_MODE}" = "master" ]; then
       echo "====>statr mysql master."
       $doCommand -p123456 -e "CREATE USER sync@'%.%.%.%' IDENTIFIED BY '123456';GRANT REPLICATION SLAVE ON *.* TO sync@'%.%.%.%' IDENTIFIED BY '123456'; FLUSH PRIVILEGES;"
     fi
     if [ "${START_MODE}" = "slave" ]; then
       echo "====>statr mysql slave."
       $doCommand -p123456 -e "CHANGE MASTER TO MASTER_HOST='${MASTER_HOST}', MASTER_USER='sync', MASTER_PASSWORD='123456',MASTER_PORT=${MASTER_PORT}, MASTER_CONNECT_RETRY=5; START SLAVE; FLUSH PRIVILEGES;" 
     fi
     doSql=false
  fi
done

