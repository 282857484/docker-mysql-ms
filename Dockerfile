FROM centos:7

ADD Percona-Server-5.7.13-6-re3d58bb-el7-x86_64-bundle.tar /Percona-Server-5.7.13-6-re3d58bb-el7-x86_64-bundle
COPY percona-xtrabackup-24-2.4.4-1.el7.x86_64.rpm /percona-xtrabackup-24-2.4.4-1.el7.x86_64.rpm
COPY libev-4.15-1.el6.rf.x86_64.rpm /libev-4.15-1.el6.rf.x86_64.rpm
COPY libaio-0.3.107-10.el6.x86_64.rpm /libaio-0.3.107-10.el6.x86_64.rpm

RUN yum remove mariadb* \
    && yum install numactl-libs -y \
    && yum install net-tools -y \
    && rpm -ivh libaio-0.3.107-10.el6.x86_64.rpm \
    && yum install perl -y \
    && yum install perl-Module-Install.noarch -y

RUN groupadd mysql \
    && useradd -r -g mysql -s /bin/bash mysql \
    && cd /Percona-Server-5.7.13-6-re3d58bb-el7-x86_64-bundle \
    && rpm -ivh Percona-Server-shared-compat-57-5.7.13-6.1.el7.x86_64.rpm \
    && rpm -ivh Percona-Server-shared-57-5.7.13-6.1.el7.x86_64.rpm \
    && rpm -ivh Percona-Server-client-57-5.7.13-6.1.el7.x86_64.rpm \
    && rpm -ivh Percona-Server-server-57-5.7.13-6.1.el7.x86_64.rpm \
    && yum install -y perl-DBD-MySQL \
    && yum install -y rsync 

ENV MYSQL_HOME /percona

COPY mysql_start.sh /mysql_start.sh
COPY my.cnf $MYSQL_HOME/my.cnf 
RUN chmod 755 /mysql_start.sh $MYSQL_HOME/my.cnf 
RUN rm -rf Percona-Server-5.7.13-6-re3d58bb-el7-x86_64-bundle

RUN cd $MYSQL_HOME \
    && chown -Rf mysql:mysql $MYSQL_HOME \
    && chmod 755 -Rf $MYSQL_HOME \
    && rm -rf /etc/my.cnf 
#  && /usr/sbin/mysqld --initialize-insecure --basedir=$MYSQL_HOME --datadir=$MYSQL_HOME/data --user=mysql

VOLUME ["/aifs01/dbdata"]
WORKDIR $MYSQL_HOME

CMD ["/mysql_start.sh"]
