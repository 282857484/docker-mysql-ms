#!/bin/bash
# change env params
MASTER_HOST=${1}
MASTER_PORT=${2}
START_MODE=${3}
# change .sql file param
if [ "${START_MODE}" = "bakmaster" ]; then
  sed -i "s%MASTER_HOST=.*, MASTER_PORT%MASTER_HOST='${MASTER_HOST}', MASTER_PORT%g" /${4}.sql
  sed -i "s%MASTER_PORT=.*, MASTER_USER%MASTER_PORT=${MASTER_PORT}, MASTER_USER%g" /${4}.sql
fi
if [ "${START_MODE}" = "slave" ]; then
  sed -i "s%MASTER_HOST=.*, MASTER_PORT%MASTER_HOST='${MASTER_HOST}', MASTER_PORT%g" /${4}.sql
  sed -i "s%MASTER_PORT=.*, MASTER_USER%MASTER_PORT=${MASTER_PORT}, MASTER_USER%g" /${4}.sql
fi
# run .sql in mysql
/bin/mysql -uroot -p123456 --socket=/percona/mysqld-${PORT}.sock < /${4}.sql