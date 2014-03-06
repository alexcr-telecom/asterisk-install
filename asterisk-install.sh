#!/bin/bash
#
# This script to install the Dahdi drivers, Asterisk
# on a new install of ubuntu 
#
# Changelog:
# 1.1 - First release


# definitions of items to possibly change
export MYSQL_ROOT_PW=mahapharata
export IP_ADDRESS=192.168.1.100

# ensure package directory up to date and system upgraded
apt-get -y update
apt-get -y upgrade

# retrieve utilities and set debconf to noninteractive front-end
apt-get -y install debconf-utils
debconf-set-selections <<CONF_EOF
debconf debconf/frontend select noninteractive
CONF_EOF

# install mysql server
apt-get -y install mysql-server

# configure mysql root password
mysqladmin -u root password ${MYSQL_ROOT_PW}

debconf-set-selections <<CONF_EOF
debconf debconf/frontend select Dialog
CONF_EOF

# locale fix
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
sudo dpkg-reconfigure locales




# install packages needed beyond base install with openssh server
apt-get -y install aptitude
aptitude -y install build-essential wget libssl-dev libncurses5-dev libnewt-dev  libxml2-dev linux-headers-$(uname -r) libsqlite3-dev uuid-dev  make bison flex g++ gcc apache2 php5 php5-curl php5-cli php5-mysql php-pear php-db php5-gd curl sox libncurses5-dev libssl-dev libmysqlclient15-dev mpg123 unixODBC unixODBC-dev  mysql-connector-odbc libmyodbc install subversion git fail2ban mc htop vim

#clear

# place source packages in standard place
cd /usr/src

# download, make, install, and configure
wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/libpri/libpri-1.4-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-11-current.tar.gz

tar zxvf dahdi-linux-complete*
tar zxvf libpri*
tar zxvf asterisk*

cd /usr/src/dahdi-linux-complete*
make && make install && make config

cd /usr/src/libpri*
make && make install

cd /usr/src/asterisk*
./configure && make menuselect && make && make install && make config && make samples




#Add Asterisk group and user
grep -c "^asterisk:" /etc/group &> /dev/null
if [ $? = 1 ]; then
       /usr/sbin/groupadd -r -f asterisk
else
       echo "group asterisk already present"
fi

grep -c "^asterisk:" /etc/passwd &> /dev/null
if [ $? = 1 ]; then
       echo "adding user asterisk..."
       /usr/sbin/useradd -c "Asterisk" -g asterisk \
       -r -s /bin/bash -m -d /var/lib/asterisk \
       asterisk
else
       echo "user asterisk already present"
fi



chown -R asterisk:asterisk /var/log/asterisk/ /etc/asterisk/ /var/lib/asterisk/ /var/run/asterisk
#bit of a bodge here, just incase this script gets run twice
sed -i 's/\/var\/run\/asterisk/\/var\/run/g'  /etc/asterisk/asterisk.conf
sed -i 's/\/var\/run/\/var\/run\/asterisk/g'  /etc/asterisk/asterisk.conf

#Setup log rotation

touch /etc/logrotate.d/asterisk
echo '

/var/log/asterisk/*log {
   missingok
   rotate 5
   weekly
   create 0640 asterisk asterisk
   postrotate
       /usr/sbin/asterisk -rx 'logger reload' > /dev/null 2> /dev/null
   endscript
}

/var/log/asterisk/full {
   missingok
   rotate 5
   daily
   create 0640 asterisk asterisk
   postrotate
       /usr/sbin/asterisk -rx 'logger reload' > /dev/null 2> /dev/null
   endscript
}

/var/log/asterisk/messages {
   missingok
   rotate 5
   daily
   create 0640 asterisk asterisk
   postrotate
       /usr/sbin/asterisk -rx 'logger reload' > /dev/null 2> /dev/null
   endscript
}

/var/log/asterisk/cdr-csv/*csv {
  missingok
  rotate 5
  monthly
  create 0640 asterisk asterisk
}

'  > /etc/logrotate.d/asterisk


chown -R asterisk:asterisk /var/log/asterisk/ /etc/asterisk/ /var/lib/asterisk/ /var/run/asterisk /var/spool/asterisk



# setup databases 
mysqladmin -u root -p${MYSQL_ROOT_PW} create asteriskcdrdb
mysql -u root -p${MYSQL_ROOT_PW} asteriskcdrdb < SQL/cdr_mysql_table.sql
mysql -u root -p${MYSQL_ROOT_PW} <<-END_PRIVS
	GRANT ALL PRIVILEGES ON asterisk.* TO asteriskuser@localhost IDENTIFIED BY "${ASTERISK_DB_PW}";
	GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO asteriskuser@localhost IDENTIFIED BY "${ASTERISK_DB_PW}";
	flush privileges;
END_PRIVS


# start apache web server
/etc/init.d/apache2 restart

# load up dahdi drivers
/etc/init.d/dahdi restart

clear
# voila!
echo "#####################################################"
echo "					   		"
echo "	Now, point your browser to:"
echo "	`${IP_ADDRESS}`/admin"
echo " Also, check: http://wiki.ubuntu.com/AsteriskOnUbuntu"
echo " to learn how to fine tune you PBX!"
echo " "
echo "bye! Ubuntu Asterisk Team!"
