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
#    && rpm -ivh Percona-Server-57-debuginfo-5.7.13-6.1.el7.x86_64.rpm \
#    && rpm -ivh Percona-Server-devel-57-5.7.13-6.1.el7.x86_64.rpm \
#    && rpm -ivh Percona-Server-test-57-5.7.13-6.1.el7.x86_64.rpm \
#    && rpm -ivh Percona-Server-tokudb-57-5.7.13-6.1.el7.x86_64.rpm \
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

####ADD 20160908 10:45 HB s
RUN mkdir /percona/lib64
RUN mkdir /percona/lib64/mysql
RUN mkdir /percona/lib64/mysql/plugin
COPY audit5_7_9.so /audit5_7_9.so
COPY libimf.so /percona/lib64/mysql/plugin/libimf.so
RUN mv /audit5_7_9.so /percona/lib64/mysql/plugin/audit_log.so
RUN mv /usr/lib64/mysql/plugin/* /percona/lib64/mysql/plugin/

COPY switch.sh /switch.sh
COPY bakmaster_switch.sql /bakmaster_switch.sql
COPY master_switch.sql /master_switch.sql
COPY slave_switch.sql /slave_switch.sql
RUN chmod 777 /switch.sh 
####ADD 20160908 10:45 HB e

VOLUME ["/aifs01/dbdata"]
WORKDIR $MYSQL_HOME

CMD ["/mysql_start.sh"]
