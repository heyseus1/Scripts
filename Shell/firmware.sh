#!/bin/bash
# FIRMWARE ver.
# w00t be in r00t


header() { 
echo '' 
echo -e "----------------------" 
echo -e " [*] $title " 
echo -e "----------------------" 
}

checkroot() {
	if [ $UID -ne 0 ] ; then
		echo "User has insufficient privilege."
		exit 4
	fi
}


explain() {
	title="fw-info"
	header $title
	MCinfo=`/usr/bin/ipmitool bmc info | egrep -i 'Firmware revision'`
	BIOSINFO=`dmidecode -t bios -q | egrep -i 'version|release' `
	if [ -n "$( /usr/sbin/dmidecode | grep 'Manufacturer: HP')" ]; then
    echo This HP ilo version is $MCinfo
  	else
    echo This Dell idrac version is $MCinfo
	fi
	if [ -n "$( /usr/sbin/dmidecode | grep 'Manufacturer: HP')" ]; then
    echo This HP BIOS version is $BIOSINFO
	else   
    echo This Dell BIOS version is $BIOSINFO
	fi
}

display_firmware() {
	title="Display_firmware"
	header $title
	dmidecode -t 1 | grep -i 'serial' | sed 's/^	*//' 
	cat /etc/*-release | uniq 
	dmidecode -t system -q | egrep -i 'Manufacturer: |Product' | \
	sed 's/^	*//' 
	/usr/bin/ipmitool bmc info | egrep -i 'Firmware revision'
	dmidecode -t bios -q | egrep -i 'version|vendor|release|BIOS revision' | \
	sed 's/^	*//' 
}

show_hp_fw() {
	if [ -n "$( /usr/sbin/dmidecode | grep 'Manufacturer: HP')" ]; then
		title="HP-Raid-Firmware"
		header $title
		hpacucli  ctrl all show config detail | egrep -i 'Firmware Version:'| \
		sed 's/^ *//' 
	else
		echo "skipping HP firmware check" 
	fi
}

show_disks_dell() {
	if [ -n "$( /usr/sbin/dmidecode | grep 'Manufacturer: Dell')" ] ; then
		title="Dell-Raid-Firmware" 
		header $title
		/opt/MegaRAID/MegaCli/MegaCli64 -AdpAllInfo -aALL | \
		egrep -i 'Product Name|Serial No|FW Package Build' 
	else
		echo "skipping Dell firmware check" 
	fi
}

display_networking() {
	title="Networking"
	header $title
	INTS=`ifconfig | cut -f1 -d: | egrep -v '^\s' | awk '{print $1}' | egrep -v '^$|Interrupt|UP|lo|inet'`   
	for int in $INTS; do
		echo "Int: $int"
	/usr/sbin/ethtool $int| egrep -i 'eth' | ruby -ne 'puts " " * 4 + $_' 
	/usr/sbin/ethtool -i $int | egrep -i 'version|driver' | ruby -ne 'puts " " * 4 + $_' 
	done
}

service ipmi start
explain 
display_firmware 
show_hp_fw 
show_disks_dell 
display_networking 