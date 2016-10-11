#!/bin/bash

doFlag=true
lockFile=/percona/mysqld-${PORT}.sock.lock
doCommand="mysql -uroot --socket=${MYSQL_HOME}/mysqld-${PORT}.sock"

sed -i "s%port=3306%port=${PORT}%g" ${MYSQL_HOME}/my.cnf
sed -i "s%socket=.*%socket=${MYSQL_HOME}\/mysqld-${PORT}.sock%g" ${MYSQL_HOME}/my.cnf
sed -i "s%pid-file=.*%pid-file=${MYSQL_HOME}\/mysql-${PORT}.pid%g" ${MYSQL_HOME}/my.cnf
sed -i "s%log-error=.*%log-error=${MYSQL_HOME}\/data\/mysql-${PORT}.err%g" ${MYSQL_HOME}/my.cnf
sed -i "s%server-id=1%server-id=${SERVER_ID}%g" ${MYSQL_HOME}/my.cnf

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
####ADD 20160908 10:45 HB s
     if [ "${SQL_AUDIT}" = "on" ]; then
       $doCommand -p123456 -e "INSTALL PLUGIN audit_log SONAME 'audit_log.so';"
       $doCommand -p123456 -e "set global audit_myswitch=on;"
       $doCommand -p123456 -e "set global audit_sql='delete;select;drop';"
     fi
####ADD 20160908 10:45 HB e
     if [ "${START_MODE}" = "master" ]; then
       echo "====>start mysql master."
       $doCommand -p123456 -e "GRANT REPLICATION SLAVE ON *.* TO sync@'%.%.%.%' IDENTIFIED BY '123456'; FLUSH PRIVILEGES;"
       echo "====>create user sync on master."
####ADD 20160908 10:45 HB s
       if [ "${SYNC_STRATEGY}" = "semisynchronous" ]; then
         $doCommand -p123456 -e "INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';"
         $doCommand -p123456 -e "SET GLOBAL rpl_semi_sync_master_enabled = 1;"
         $doCommand -p123456 -e "SET GLOBAL rpl_semi_sync_master_timeout = 1000;"
       fi
       var=${DB_WHITE_LIST}
       var=${var//,/ }
       for element in $var
       do
           echo $element
           $doCommand -p123456 -e "GRANT ALL PRIVILEGES ON *.* TO ${DB_ROOT_NAME}@'$element' IDENTIFIED BY '${DB_ROOT_PASSWORD}' WITH GRANT OPTION;FLUSH PRIVILEGES;"
       done
####ADD 20160908 10:45 HB e
     fi
     if [ "${START_MODE}" = "slave" ]; then
       echo "====>statr mysql slave."
       $doCommand -p123456 -e "GRANT REPLICATION SLAVE ON *.* TO sync@'%.%.%.%' IDENTIFIED BY '123456'; FLUSH PRIVILEGES;"
       $doCommand -p123456 -e "CHANGE MASTER TO MASTER_HOST='${MASTER_HOST}', MASTER_USER='sync', MASTER_PASSWORD='123456',MASTER_PORT=${MASTER_PORT}, MASTER_CONNECT_RETRY=5; START SLAVE; FLUSH PRIVILEGES;" 
####ADD 20160908 10:45 HB s
       if [ "${SYNC_STRATEGY}" = "semisynchronous" ]; then
         $doCommand -p123456 -e "INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';"
         $doCommand -p123456 -e "SET GLOBAL rpl_semi_sync_slave_enabled = 1;"
         $doCommand -p123456 -e "STOP SLAVE IO_THREAD; START SLAVE IO_THREAD;"
       fi
       var=${DB_WHITE_LIST}
       var=${var//,/ }
       for element in $var
       do
           echo $element
           $doCommand -p123456 -e "GRANT ALL PRIVILEGES ON *.* TO ${DB_ROOT_NAME}@'$element' IDENTIFIED BY '${DB_ROOT_PASSWORD}' WITH GRANT OPTION;FLUSH PRIVILEGES;"
       done 
####ADD 20160908 10:45 HB e
       sed -i "s%1%2%g" ${MYSQL_HOME}/data/auto.cnf 
       /usr/bin/mysqladmin --port=${PORT} -uroot -p123456 shutdown
       /usr/sbin/mysqld --defaults-file=${MYSQL_HOME}/my.cnf --basedir=${MYSQL_HOME} --port=${PORT} --user=mysql &
       echo "modified service-uuid and restart slave."

    fi
    doFlag=false
  fi
done

