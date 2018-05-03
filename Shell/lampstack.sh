#!/bin/bash

checkroot() {
	if [ $UID -ne 0 ] ; then
		echo "User has insufficient privilege."
		exit 4
	fi
}

install_deps () {
	apt-get update
	apt-get upgrade
	apt-get -y install \
	vim curl apache2 mysql-server mysql-client php5 php5-mysql libapache2-mod-php5 php5-curl php5-mcrypt php-pear

}

configure_php () {
echo '<?php
phpinfo();
?>' >> /var/www/html/test.php
}

checkroot
install_deps
configure_php
