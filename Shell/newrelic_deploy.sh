#!/bin/bash
# w00t be in r00t

checkroot() {
	if [ $UID -ne 0 ] ; then
		echo "User has insufficient privilege."
		exit 4
	fi
}

install_deps() {
	apt-get -y install curl apt-transport-https
}

check_debian() {
	if [ -n "$(cat /etc/*-release | grep -i 'ID=debian')" ] ; then
		os=`cat /etc/*-release | grep 'VERSION' | awk '{print $2}' |  sed -e "s/(//" | sed -e 's/)"//' | perl -ne 'print lc'`
		echo "license_key: insert key here" | tee -a /etc/newrelic-infra.yml
		curl https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | apt-key add -
		printf "deb [arch=amd64] https://download.newrelic.com/infrastructure_agent/linux/apt `echo ${os}` main" | \
		sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list
		apt-get update
		apt-get install newrelic-infra -y
	else
		echo "skipping debian"
	fi
}

check_ubuntu() {
	if [ -n "$(cat /etc/*-release | grep -i 'ID=ubuntu')" ] ; then
		os=`cat /etc/*-release | grep 'VERSION' | awk '{print $3}' | sed -e "s/(//" | perl -ne 'print lc'`
		echo "license_key: insert key here" | tee -a /etc/newrelic-infra.yml
		curl https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | apt-key add -
		printf "deb [arch=amd64] https://download.newrelic.com/infrastructure_agent/linux/apt `echo ${os}` main" | \
		sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list
		apt-get update
		apt-get install newrelic-infra -y
	else
		echo "skipping ubuntu"
	fi
}


check_amazon() {
	if [ -n "$(cat /etc/*-release | grep -i 'ID="amzn"')" ] ; then
		echo "license_key: insert key here" | sudo tee -a /etc/newrelic-infra.yml
		curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/el/6/x86_64/newrelic-infra.repo
		yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'
		yum install newrelic-infra -y
	else
		echo "skipping amazon"
	fi
}

check_centos7() {
	if [ -n "$(cat /etc/*-release | grep -i 'ID="centos"')" ] ; then
		echo "license_key: insert key here" | sudo tee -a /etc/newrelic-infra.yml
		curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/el/7/x86_64/newrelic-infra.repo
		yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'
		yum install newrelic-infra -y
	else
		echo "skipping centos7"
	fi
}

check_centos6() {
	if [ -n "$(cat /etc/*-release | grep -i 'CentOS release 6')" ] ; then
		echo "license_key: insert key here" | sudo tee -a /etc/newrelic-infra.yml
		curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/el/6/x86_64/newrelic-infra.repo
		yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'
		yum install newrelic-infra -y
	else
		echo "skipping centos7"
	fi
}

install_deps
checkroot
check_debian
check_ubuntu
check_amazon
check_centos7
check_centos6
