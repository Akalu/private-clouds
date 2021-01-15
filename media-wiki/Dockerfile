FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London

# cd /usr/local/runme
WORKDIR /usr/local/runme

ARG SQL_SCRIPT=./db/010_init.sql

# copy to working directory
COPY ${SQL_SCRIPT} /usr/local/runme/010_init.sql

RUN apt-get update
RUN apt-get install -y apache2

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

RUN apt-get install -y php libapache2-mod-php nano
RUN apt-get install -y wget
RUN wget https://releases.wikimedia.org/mediawiki/1.30/mediawiki-1.30.0.tar.gz
RUN tar xzvf mediawiki-1.30.0.tar.gz
RUN mkdir /var/www/html/mediawiki
RUN cp -r mediawiki-1.30.0/* /var/www/html/mediawiki
 
RUN apt-get install -y php7.4-mbstring php7.4-xml php7.4-mysql php-apcu php-imagick

ENTRYPOINT /etc/init.d/apache2 start && /etc/init.d/mysql start && bash


	


