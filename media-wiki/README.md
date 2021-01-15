
About 
======

This is an implementation of content management system (CMS) on the basis of LAMP stack.  


Manual approach
================

Steps (1) and (2) can be omitted if you are already on Linux

1) Builds image with Ubuntu distribution and tag linux:20.04. Note the dot at the end of the command.
```
docker build -f Dockerfile-min -t linux:20.04 .
```

2) Instantiates container and connects it to standard console.
```
docker run -p 8082:80 -it linux:20.04 /bin/bash
```

3) Installing Apache itself is easy.
```
apt-get install -y apache2
```

4) Run Apache Server.

```
/etc/init.d/apache2 start
```

You should get:
```
 * Starting Apache httpd web server apache2                                                                             
AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.17.0.2. Set the 'ServerName' directive globally to suppress this message *
```
Note the ip address - this is not the ip address of container

After navigating to http://localhost:8082/ you should see the "Apache2 Ubuntu Default Page"

5) Installing an SQL database 

```
apt-get install -y mariadb-server systemctl
```

You can confirm the DB is running using direct command or systemctl:
```
mysql --version
mysql  Ver 15.1 Distrib 10.3.25-MariaDB, for debian-linux-gnu (x86_64) using readline 5.2
```

If not running, start it:
```
service mysql start
```

6) Securing DB

```
mysql -u root -p 
```

MariaDB might not let you log in unless you run the mysql command as sudo. If this happens, log in using sudo and provide the MariaDB password you created. Then run these three commands at the MySQL prompts (substituting your password for your-password):

```
SET PASSWORD = PASSWORD('admin123'); 
update mysql.user set plugin = 'mysql_native_password' where User='root'; 
FLUSH PRIVILEGES;
```

The next time you log in, you should no longer require sudo and, more importantly, MediaWiki should be able to do its job properly.

7) Creating a MediaWiki DB User 

```
CREATE DATABASE wikidb;
CREATE USER 'mw-admin'@'localhost' IDENTIFIED BY 'wiki-password'; 
GRANT ALL PRIVILEGES ON wikidb.* TO 'mw-admin'@'localhost' IDENTIFIED BY 'wiki-password'; 
FLUSH PRIVILEGES; 
``` 

8) Installing PHP
```
apt-get install -y php libapache2-mod-php nano
```

9) Testing PHP installation (optional)

To make sure your PHP installation is live (and to learn about PHP’s local environment and resource integration), create a new file using the .php filename extension in the Apache web document root directory. Then fill the file with the remaining lines of text like so:

```
# nano /var/www/html/testmyphp.php 
```

The content of file is:
```
<?php 
   phpinfo(); 
?>
```

restart apache server:
```
/etc/init.d/apache2 restart
```

Now head over to a browser, enter the IP address of the machine that’s running PHP (or localhost, if it’s the desktop you’re working on) and the name of the file you created:
```
http://localhost:8082/testmyphp.php
```

10) Installing and configuring MediaWiki 

Head over to the MediaWiki download page (www.mediawiki.org/wiki/Download) to get the latest package

```
apt-get install -y wget
wget https://releases.wikimedia.org/mediawiki/1.30/mediawiki-1.30.0.tar.gz
```

then unpack and copy sources to apache public webdir:
```
tar xzvf mediawiki-1.30.0.tar.gz
ls mediawiki-1.30.0 mediawiki-1.30.0.tar.gz
mkdir /var/www/html/mediawiki
cp -r mediawiki-1.30.0/* /var/www/html/mediawiki
```

Navigate to http://localhost:8082/mediawiki/index.php to check the website is up and running
In case of any errors from "missing php extensions" category (f.e. You are missing a required extension to PHP that MediaWiki requires to run: mbstring) do the following:

a) use apt search to see what packages relate to mbstring. Since the running version of PHP is 7, the php7.4-mbstring package seems like the one most likely one to search of, see the output of the following command:

```
apt search mbstring 
```

b) install necessary packages and restart Apache (in this case it is 4 packages, including php7.4-mbstring at al.)
```
apt-get install -y php7.4-mbstring php7.4-xml php7.4-mysql php-apcu php-imagick 
/etc/init.d/apache2 restart
```

11) Connecting MediaWiki to the database 

After restart click on complete the installation link and fill out necessary fields (must use wikidb and wiki user created earlier)
In the end download LocalSettings.php file. This file must be put into MediaWiki root (installation) directory, i.e. /var/www/html/mediawiki. Copy the file to MediaWiki's root dir:

```
docker cp LocalSettings.php my_container_id:/var/www/html/mediawiki/LocalSettings.php
```
If necessary, one can exit bash console in container and connect to it:

```
docker exec -it my_container_id /bin/bash
```

Restart apache once again and navigate browser to the main page:
```
http://localhost:8082/mediawiki/index.php
```

Automated approach
===================

Use Dockerfile file to perform steps 1-10; perform step 11 manually:
```
docker build -f Dockerfile -t linux-media-wiki:20.04 .
```

2) Instantiates container and connects it to standard console.
```
docker run -p 8082:80 -it linux-media-wiki:20.04 /bin/bash
```

3) Execute the sql script:
```
mysql -u root -p < 010_init.sql;
```

4) navigate browser to the main page and complete the installation:
```
http://localhost:8082/mediawiki/index.php
```
NOTE: installation must be completed manually, because during the last steps all necessary db tables are created

5) Restart apache once again and navigate browser to the main page. We are done!

References
===========
More about MediaWiki: [https://www.mediawiki.org/wiki/MediaWiki]


Notes
======

Additional useful commands:

Clean up local docker registry:
```
docker image prune -a --force --filter "until=2021-01-04T00:00:00"
```

Add exemptions to docker registries:
```
{
  "registry-mirrors": [],
  "insecure-registries": [
    "reg.domain.com"
  ],
  "debug": true,
  "experimental": false
}
```
