#!/bin/bash
# Linux host info script
# Matthew Morcaldi 2015
# DONUTS version 0.2.8 last update (9/18/2015)
# w00t be in r00t

# Config ------------------------------------------------
outfile="${HOSTNAME}_linux_info.txt"
#--------------------------------------------------------




ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"


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

display_os() {
	title="Display_OS"
	header $title
	service ipmi start
	/bin/date | tee -a $outfile
	/bin/uname -r | tee -a $outfile
	dmidecode -t 1 | grep -i 'serial' | sed 's/^	*//' | tee -a $outfile
	cat /etc/*-release | tee -a $outfile
	dmidecode -t system -q | egrep -i 'Manufacturer: |Product|UUID' | \
	sed 's/^	*//' | tee -a $outfile
	/usr/bin/ipmitool bmc info | egrep -i 'Firmware revision' | tee  -a $outfile
	dmidecode -t bios -q | egrep -i 'version|vendor' | \
	sed 's/^	*//' | tee -a $outfile
	service ipmi stop

}

display_mount() {
	title="Mount"
	header $title
	mount |column -t | tee -a $outfile
}

display_network_oob() {
	title="Drac-Info"
	header $title
	service ipmi start
	ipmitool lan print | egrep -i 'IP Address|MAC Address|Default Gateway IP|Subnet Mask' | tee -a $outfile
	service ipmi stop
}

display_networking() {
	title="Networking"
	header $title
	INTS=`ifconfig | cut -f1 -d: | egrep -v '^\s' | awk '{print $1}' | egrep -v '^$|Interrupt|UP|lo|inet'`
	for int in $INTS; do
		echo "Int: $int"
	/usr/sbin/ethtool $int| egrep -i 'eth|speed|duplex|link detected' | tee -a $outfile
	/usr/sbin/ethtool -i $int | egrep -i 'version|driver' | tee -a $outfile
	done
	ifconfig -a | tee -a $outfile
	arp -e | tee -a $outfile

}

display_bonding() {
	if [ -f /proc/net/bonding/bond0 -a -f /bin/netstat ] ; then
		title="Bonding"
		header $title
		cat /proc/net/bonding/bond0 | sed 's/^ *//' | tee -a $outfile
		/bin/netstat -ni | column -t | tee -a $outfile
	else
		echo "Bond0 or netstat does not exist skipping"
	fi
}

display_switch_info() {
	if [ -f /usr/sbin/lldpctl ] ; then
		title="Switch-Port-Information"
		header $title
		lldpctl | egrep '(Interface|VLAN|PortDescr|SysName|ChassisID)' | \
		sed 's/^ *//' | tee -a $outfile
	else
		echo "Switch file LLDPCTL does not exist skipping"
	fi
}

display_sockets () {
	if [ -f /usr/sbin/lsof ] ; then
		title="Sockets"
		header $title
		/usr/sbin/lsof -nP | grep TCP | column | tee -a $outfile
		/usr/sbin/lsof -nP | grep UDP | column | tee -a $outfile
		/usr/sbin/lsof -i | grep LISTEN | column -t | tee -a $outfile
		/usr/sbin/lsof -i | grep ESTABLISHED | column -t | tee -a $outfile
	else
		echo "lsof does not exist skipping"
	fi
}

display_CPU_info() {
	title="CPU-Info"
	header $title
	CPUFILE=/proc/cpuinfo
	test -f $CPUFILE || exit 1
	NUMPHY=`grep "physical id" $CPUFILE | sort -u | wc -l`
	NUMLOG=`grep "processor" $CPUFILE | wc -l`
	if [ $NUMPHY -eq 1 ]
  	then
    echo This system has one physical CPU, | tee -a $outfile
  	else
    echo This system has $NUMPHY physical CPUs, | tee -a $outfile
	fi
	if [ $NUMLOG -gt 1 ]
  	then
    echo and $NUMLOG logical CPUs. | tee -a $outfile
    NUMCORE=`grep "core id" $CPUFILE | sort -u | wc -l`
    if [ $NUMCORE -gt 1 ]
    then
    echo For every physical CPU there are $NUMCORE cores. | tee -a $outfile
    fi
  	else
    echo and one logical CPU. | tee -a $outfile
	fi
	echo -n The CPU is a `grep "model name" $CPUFILE | sort -u | cut -d : -f 2-` | tee -a $outfile
	echo " with`grep "cache size" $CPUFILE | sort -u | cut -d : -f 2-` cache" | tee -a $outfile
}

show_disks_dell() {
	if [ -n "$( /usr/sbin/dmidecode | grep 'Manufacturer: Dell')" ] ; then
		title="Dell-Raid"
		header $title
		/opt/MegaRAID/MegaCli/MegaCli64 -PDList -aAll | \
		egrep -i 'Raw Size:|count|^Device Id: |firmware state' | \
		grep -v 'Count: 0' | perl -p -e 's/Firmware state: (.*)$/Firmware state: $1\n/' | \
		ruby -ne 'puts " " * 4 + $_' | tee -a $outfile
		/opt/MegaRAID/MegaCli/MegaCli64 -AdpAllInfo -aALL | \
		egrep -i 'Product Name|Serial No|FW Package Build' |tee -a $outfile
	else
		echo "skipping Dell disk check"
	fi
}

show_battery_dell() {
	if [ -n "$( /usr/sbin/dmidecode | grep 'Manufacturer: Dell')" ]; then
		title="Dell-Battery"
		header $title
		/opt/MegaRAID/MegaCli/MegaCli64 -AdpBbuCmd -GetBbuStatus -a0 | \
		egrep -i 'isSOHGood|Charger Status|Capacity|Relative|Charging' | \
		sed 's/^ *//' | tee -a $outfile
	else
		echo "skipping Dell battery check"
	fi
}

show_disks_hp() {
	if [ -n "$( /usr/sbin/dmidecode | grep 'Manufacturer: HP')" ]; then
		title="HP-Raid"
		header $title
		hpacucli ctrl all show config detail | \
		sed 's/^ *//' | tee -a $outfile
		hpacucli  ctrl all show config detail | egrep -i 'Firmware Version:'| \
		sed 's/^ *//' | tee -a $outfile
	else
		echo "skipping HP disk check"
	fi
}

show_battery_hp() {
	if [ -n "$( /usr/sbin/dmidecode | grep 'Manufacturer: HP')" ]; then
		title="HP-Battery"
		header $title
		hpacucli ctrl all show status | \
		sed 's/^ *//' | tee -a $outfile
	else
		echo "skipping HP battery check"
	fi
}

show_psu() {
	title="PSU Status"
	header $title
	service ipmi start
	dmidecode -t 39 | tee -a $outfile
	ipmitool sdr type 'Power Supply' | tee -a $outfile
	ipmitool sdr elist | \
	egrep -i 'PS2 PG Fail|PS1 PG Fail|Power Cable|PS Redundancy|Pwr Consumption|Current 1|Current 2|Voltage 1| Voltage 2' | \
	tee -a $outfile
	service ipmi stop
}

display_fan() {
	title="Display Fan"
	header $title
	service ipmi start
	ipmitool sdr elist | egrep -i fan | tee -a $outfile
	service ipmi stop
}

show_sysprofile_dell() {
	if [ -n "$( /usr/sbin/dmidecode | grep 'Manufacturer: Dell')" ]; then
		title="BIOS power settings Dell"
		header $title
		ohai vendorbios/syscfg -d /etc/chef/ohai_plugins/ | \
		egrep -i 'MemTest|MemOpMode|LogicalProc|ProcVirtualization|ProcCores|BootMode|SerialComm|SysProfile|ProcPwrPerf|MemFrequency|ProcTurboMode' | \
		tee -a $outfile
		ohai vendorbios/power -d /etc/chef/ohai_plugins/ | tee -a $outfile
	else
		echo "skipping Dell power settings check"
	fi
}

show_sysprofile_HP() {
	if [ -n "$( /usr/sbin/dmidecode | grep 'Manufacturer: HP')" ]; then
		title="BIOS power settings HP"
		header $title
		ohai vendorbios/conrep -d /etc/chef/ohai_plugins/ | tee -a $outfile
		ohai vendorbios -d /etc/chef/ohai_plugins/ | \
		egrep -i 'hyperthreading|cpu_performance|hp_power_regulator|hp_dynamic_smart_array_raid_controller|cpu_virtualization|hp_power_profile|intel_hyperthreading|redundant_power_supply_mode|energy_performance_bias|intel_dimm_voltage_preference|memory_power_savings_mode' | \
		tee -a $outfile

	else
		echo "skipping HP power settings check"
	fi
}

display_dimms() {
	title="Memory"
	header $title
	display_mce
	cat /proc/meminfo|grep MemTotal | tee -a $outfile
	free -g | tee -a $outfile
	dmidecode -t Memory Device -q |egrep -i 'Size:|Type: D|Locator: D' | \
	perl -p -e 's/Type: (.*)$/Type: $1\n/' | tee -a $outfile

}

display_mce() {
	if [ -f /var/log/mcelog ] ; then
		grep -E 'CPU.*BANK.*' /var/log/mcelog | sort | uniq -c
	else
		echo "skipping mcelog"
	fi

}

sel_list() {
	title="SEL"
	header $title
	service ipmi start
	ipmitool sel elist | tee -a $outfile
	service ipmi stop

}

exit_script() {
	title="exit_script"
	header $title
	exit 0

}

run_all() {
	display_os; display_mount; display_CPU_info; display_dimms; sel_list; show_psu; display_fan; show_sysprofile_dell; \
	show_sysprofile_HP; show_disks_hp; show_battery_hp; show_disks_dell; show_battery_dell; \
	display_network_oob; display_networking; display_bonding; display_switch_info; display_sockets; exit_script
}

run_all2() {
	display_os; display_mount; display_CPU_info; display_dimms; sel_list; show_psu; display_fan; show_sysprofile_dell; \
	show_sysprofile_HP; show_disks_hp; show_battery_hp; show_disks_dell; show_battery_dell; \
	display_network_oob; display_networking; display_bonding; display_switch_info; display_sockets
}

hardware_all() {
	display_os; display_CPU_info; display_dimms; sel_list; show_psu; display_fan ; show_disks_hp; show_battery_hp; \
	show_disks_dell; show_battery_dell; exit_script
}

network_all() {
	display_network_oob; display_networking; display_bonding; display_switch_info; display_sockets; exit_script
}

purge() {
	rm *_linux_info.txt
	echo "${HOSTNAME}_linux_info.txt deleted"
	rm *_linux_info.zip
	echo "${HOSTNAME}_linux_info.zip deleted"
}

email2() {
	purge ; run_all2 ; email
}

email() {
	echo "compressing file"
	zip ${HOSTNAME}_linux_info.zip ${HOSTNAME}_linux_info.txt
	(cat ${HOSTNAME}_linux_info.zip) | mail -s "linux_info" -r "${HOSTNAME}@gmail.com" ${SUDO_USER}@gmail.com
	echo "Email delivered to ${SUDO_USER}@gmail.com"
	exit 0
}

usage () {
	echo -e "$COL_RED welcome to DONUTS!!! $COL_RESET"
	echo -e "$COL_GREEN DONUTS version 0.2.8 last update (9/18/2015) $COL_RESET"
	echo -e "$COL_GREEN questions/improvements email matthew.morcaldi@workday.com $COL_RESET"
	echo -e "$COL_MAGENTA -h = help $COL_RESET"
	echo -e "$COL_MAGENTA -a = run display all $COL_RESET"
	echo -e "$COL_MAGENTA -n = run network all $COL_RESET"
	echo -e "$COL_MAGENTA -H = run hardware all $COL_RESET"
	echo -e "$COL_MAGENTA -d = run debug mode $COL_RESET"
	echo -e "$COL_MAGENTA -p = purge file linux_info.txt $COL_RESET"
	echo -e "$COL_MAGENTA -mail = purge file, run all, and email linux_info.zip $COL_RESET"
	exit 0
}

usage1 () {
	echo -e "$COL_RED DONUTS version 2.8 $COL_RESET"
	echo -e "$COL_RED no flag applied add -h for list of commands $COL_RESET"
}

debug () {
	set -x
	run_all
}


##########


checkroot

if [ "$1x" = "-hx" -o "$2x" = "-hx" ] ; then
	usage
elif [ "$1x" = "-ax" ] ; then
	run_all
elif [ "$1x" = "-nx"  ]; then
	network_all
elif [ "$1x" = "-Hx" ]; then
	hardware_all
elif [ "$1x" = "-dx" ]; then
	debug
elif [ "$1x" = "-px" ]; then
	purge
elif [ "$1x" = "-mailx" ]; then
	email2
else
	usage1
fi



while true
do
	echo -e "$COL_RED Menu: $COL_RESET"

	FUNCTION_COUNT=24
	STUFFTODOFUNC=("display_os" "display_mount" "display_CPU_info" "display_dimms" "sel_list" "show_psu" "display_fan" "show_sysprofile_HP" "show_disks_hp" "show_battery_hp" "show_sysprofile_dell" "show_disks_dell" "show_battery_dell" "display_network_oob" "display_networking" "display_bonding" "display_switch_info" "display_sockets" "run_all" "hardware_all" "network_all" "email2" "purge" "exit_script" )
	STUFFTODONAME=('Display_OS' 'Display_Mount_Info' 'Display_CPU_Info' 'Display_Memory' 'System_Event_List' 'PSU_Status' 'Display_Fan' 'HP_BIOS_Power_Settings' 'HP_RAID' 'HP_RAID_Battery' 'Dell_BIOS_Power_Settings' 'Dell_RAID' 'Dell_RAID_Battery' 'Display_Network_OOB' 'Display_Network' 'Display_bonding' 'Display_Switch_Port_Information' 'Display_Sockets' 'Run_all' 'Hardware_all' 'Network_all' 'Run_all_and_email' 'Purge' 'Exit')
	COUNT=0
	for ITEM in ${STUFFTODONAME[*]}
	do
		echo " ${COUNT}. ${ITEM}  " | tr '_' ' '
		COUNT=$(( $COUNT + 1 ))
	done
	echo ""
	echo -n "Please Select From Above.:"
	read FUNCTION
	echo ${STUFFTODONAME[FUNCTION]}
	echo ""
	${STUFFTODOFUNC[FUNCTION]}

done
