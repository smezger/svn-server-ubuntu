FROM ubuntu:latest
#Author Sebastian Mezger <s.mezger@gmail.com>

# Install apache, svn, php
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y apache2 apache2-utils subversion libapache2-mod-svn wget unzip php php-json libapache2-mod-php php-xml

#Create directories and set permissions
RUN mkdir /home/svn && touch /etc/subversion/passwd && chown www-data /etc/subversion/passwd && chown www-data /home/svn

#enable dav_fs dav_svn is already enabled
RUN a2enmod dav_fs

#  svnadmin
RUN wget --no-check-certificate https://github.com/mfreiholz/iF.SVNAdmin/archive/stable-1.6.2.zip &&\
	unzip stable-1.6.2.zip -d /opt &&\
	rm stable-1.6.2.zip &&\
	mv /opt/iF.SVNAdmin-stable-1.6.2 /opt/svnadmin &&\
	ln -s /opt/svnadmin /var/www/html/svnadmin &&\
	chmod -R 777 /opt/svnadmin/data

# Fixing https://github.com/mfreiholz/iF.SVNAdmin/issues/118
ADD svnadmin/classes/util/global.func.php /opt/svnadmin/classes/util/global.func.php

#Adding template data for svnadmin to already set pathes
ADD svnadmin/data/config.tpl.ini /opt/svnadmin/data/config.tpl.ini

#Restart Apache2
RUN service apache2 restart

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

#Ports to be exposed by container
EXPOSE 80 443 3960

# Update the apache site with the svn config
ADD apache2_svn.conf /etc/apache2/sites-enabled/000-default.conf

#Update Auth 
ADD subversion-access-control /etc/subversion/subversion-access-control
RUN chmod a+w /etc/subversion/* && chmod a+w /home/svn

RUN svnserve -d -r /home/svn --listen-port 3960
# By default, simply start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND
