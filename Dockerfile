FROM centos:7

COPY Percona-Server-5.6.24-rel72.2-Linux.x86_64.tar /Percona-Server-5.6.24-rel72.2-Linux.x86_64.tar
COPY libaio-0.3.107-10.el6.x86_64.rpm /libaio-0.3.107-10.el6.x86_64.rpm

ENV MYSQL_HOME /percona

RUN rpm -ivh libaio-0.3.107-10.el6.x86_64.rpm && cd / \
    && tar -xvf Percona-Server-5.6.24-rel72.2-Linux.x86_64.tar \
    && rm -rf Percona-Server-5.6.24-rel72.2-Linux.x86_64.tar \
    && mv Percona-Server-5.6.24-rel72.2-Linux.x86_64 $MYSQL_HOME \
    && chmod -Rf 755 $MYSQL_HOME \
    && yum install perl -y \
    && yum install perl-Module-Install.noarch -y \
    && groupadd mysql \
    && useradd -r -g mysql -s /bin/bash mysql

RUN sed -i 's%mysql_home%\percona%g' $MYSQL_HOME/my.cnf

RUN cd $MYSQL_HOME \
    && chown -Rf mysql:mysql $MYSQL_HOME \
    && scripts/mysql_install_db --basedir=$MYSQL_HOME --datadir=$MYSQL_HOME/data --user=mysql 

COPY start.sh /start.sh
RUN chmod 755 /start.sh

WORKDIR $MYSQL_HOME
VOLUME ["/aifs01/mysqldata"]

EXPOSE 3306

CMD ["/start.sh"]
