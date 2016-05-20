#!/bin/bash

SERVICE='httpd'
service httpd start 
if ps ax | grep -v grep | grep $SERVICE > /dev/null
then
    
    echo "$SERVICE service running, everything is fine"
else
    echo "$SERVICE is not running"
    yum –y update
    yum install httpd -y
    chkconfig httpd on
fi

SERVICE='mysqld' 
service mysqld start
if ps ax | grep -v grep | grep $SERVICE > /dev/null
then
    echo "$SERVICE service running, everything is fine"
else
    echo "$SERVICE is not running"
    yum install mysql-server -y
    yum install php php-mysql -y
    chkconfig mysqld on
fi

iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited
iptables -A INPUT -i eth0 -p tcp -m tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited
iptables-save > /etc/sysconfig/iptables

echo ServerName $HOSTNAME:80 >> /etc/httpd/conf/httpd.conf
service httpd restart
tar -xzf app.tar
rm -f app.tar

mv delete.php index.php main.php set_con.php /var/www/html/

service mysqld start
mysql -u root < create.sql
mysql -u root sisdb < sisdb.sql

groupadd www-dev
useradd webuser -g www-dev

yum -y install policycoreutils-python

semanage fcontext -l | grep '/var/www('
semanage fcontext --add --type httpd_sys_content_t '/home/proj(/.*)?'
chcon -t httpd_sys_content_t -R /var/www/
mkdir /home/proj
restorecon /home/proj
mkdir -p /home/proj/sis/logs
touch /home/proj/sis/logs/error.log
cp /var/www/html/* /home/proj/sis
chgrp -R www-dev /home/proj
chmod 755 -R /home/proj
rm -f /var/www/html/*

echo NameVirtualHost *:80 >> /etc/httpd/conf/httpd.conf
echo \<VirtualHost *:80\> >> /etc/httpd/conf/httpd.conf
echo ServerName sis.dp.ua >> /etc/httpd/conf/httpd.conf
echo ServerAlias sis.dp.ua >> /etc/httpd/conf/httpd.conf
echo DocumentRoot /home/proj/sis >> /etc/httpd/conf/httpd.conf
echo ErrorLog /home/proj/sis/logs/error.log  >> /etc/httpd/conf/httpd.conf
echo \</VirtualHost\> >> /etc/httpd/conf/httpd.conf

service httpd restart
rm -f create.sql sisdb.sql deploy_app.sh