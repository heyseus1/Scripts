#!/bin/bash
# Config ------------------------------------------------
outfile="${HOSTNAME}_audit.txt"
#--------------------------------------------------------


checkroot() {
	if [ $UID -ne 0 ] ; then
		echo "User has insufficient privilege."
		exit 4
	fi
}


header() { 
echo '' | tee -a $outfile
echo -e "----------------------" | tee -a $outfile
echo -e " [*] $title " | tee -a $outfile
echo -e "----------------------" | tee -a $outfile
}


hostnames() {
	title="Hostname"
	header $title
	hostname | tee -a $outfile
}

etc_password() {
	title="etc_password"
	header $title
	cat /etc/passwd | tee -a $outfile
}


nsswitch() {
	title="nsswitch"
	header $title
	cat /etc/nsswitch.conf | tee -a $outfile
}

rsyslog() {
	title="rsyslog"
	header $title
	cat /etc/rsyslog.d/remote.conf | tee -a $outfile
	cat  /etc/rsyslog.d/strm.conf | tee -a $outfile
}

sshd_config() {
	title="sshd_config"
	header $title
	cat /etc/ssh/sshd_config | tee -a $outfile
}

sudoers() {
	title="sudoers"
	header $title
	cat /etc/sudoers | tee -a $outfile
}

systemauth() { 
	title="systemauth"
	header $title
	cat /etc/pam.d/system-auth | tee -a $outfile
}


email() {
	echo "compressing file"
	zip ${HOSTNAME}_audit.zip $outfile
	(cat ${HOSTNAME}_audit.zip) | mail -s "SWH_Audit" -r "${HOSTNAME}@workday.com" ${SUDO_USER}@workday.com
	echo "Email delivered to ${SUDO_USER}@workday.com"
	exit 0
}

checkroot
hostnames
etc_password
nsswitch
rsyslog
sshd_config
sudoers
systemauth
#email