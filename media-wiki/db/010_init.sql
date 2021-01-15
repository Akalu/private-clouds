SET PASSWORD = PASSWORD('admin123'); 
update mysql.user set plugin = 'mysql_native_password' where User='root'; 
CREATE DATABASE wikidb;
CREATE USER 'mw-admin'@'localhost' IDENTIFIED BY 'wiki-password'; 
GRANT ALL PRIVILEGES ON wikidb.* TO 'mw-admin'@'localhost' IDENTIFIED BY 'wiki-password'; 
FLUSH PRIVILEGES; 
