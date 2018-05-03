#!/bin/bash
#
# INF-21404
# Version: 20140507.01
#
# Attempt to restore correct HWADDR in /etc/sysconfig/network-scripts/eth-{n}
#  when:
#   incorrect bonding, so real hwaddr for all 6 nics not in /proc/net/bonding/bond0
#   we are on centos 5 so ethtool -P cant do it
#   /sys/net/* has bonding virtual mac
#   ifcfg-eth{n} files have wrong or missing mac
#   lspci -vv on some hardware shows address as 0000000000
#    same with dmidecode
#   Oh and we do not want to reboot, because.
#
# Luckily, kickstart/cobbler logged to /var/log/anaconda.syslog
#
# This is perhaps one of the ugliest scripts I have ever written, but it should suffice.
#  Needed by 703 boxes not counting the lab.
#
#
ME=`uname -n`
TODAY=`date '+%Y%m%d%H%M'`

BLADEY=`dmidecode -s system-product-name | grep -c "M620"`
if [ ${BLADEY} -lt 1 ] ; then
printf "\nThis might not be a M620 blade. Cowardly refusing to run.\n"
exit 2
fi

if [ ! -s /var/log/anaconda.syslog ] ; then
printf "\nanaconda.syslog does not exist for ${ME}. Cowardly refusing to run.\n"
exit 2
fi

COUNT=`egrep -c "eth0|eth1|eth2|eth3|eth4|eth5" /var/log/anaconda.syslog`
if [ ${COUNT} -lt 6 ] ; then
printf "\nNot enough eths in anaconda.syslog for ${ME}. Cowardly refusing to run.\n"
exit 2
fi

IFS='
'

mkdir -p /root/netconfig_${TODAY}
#/bin/mv /etc/sysconfig/network-scripts/*203 /root/netconfig_${TODAY}
rsync -aq /etc/sysconfig/network-scripts/ifcfg* /root/netconfig_${TODAY}/.


# disable peth0 creation
cp -p /etc/xen/xend-config.sxp /root/netconfig_${TODAY}/
egrep -v "^\(network-script" /etc/xen/xend-config.sxp > /dev/shm/.xend.tmp
cat /dev/shm/.xend.tmp > /etc/xen/xend-config.sxp
# grep -v '^#' /etc/xen/xend-config.sxp | grep -v '^$'


# create xenbr0
if [ ! -s /etc/sysconfig/network-scripts/ifcfg-xenbr0 ] ; then
printf "DEVICE=xenbr0\nTYPE=Bridge\nONBOOT=yes\nBOOTPROTO=static\n" > /etc/sysconfig/network-scripts/ifcfg-xenbr0
fi

# create xenbr0 and move ip from bond0 to xenbr0
XENBRIPCOUNT=`egrep -c "^IPAD|^NETM" /etc/sysconfig/network-scripts/ifcfg-xenbr0`
BONDIPCOUNT=`egrep -c "^IPAD|^NETM" /etc/sysconfig/network-scripts/ifcfg-bond0`
if [ ${XENBRIPCOUNT} -lt 2 ] && [ ${BONDIPCOUNT} -gt 1 ] ; then
egrep "^IPAD|^NETM" /etc/sysconfig/network-scripts/ifcfg-bond0 >> /etc/sysconfig/network-scripts/ifcfg-xenbr0
fi

# if ip moved, delete from bond0, ensure lacp bonding
IPNETM=`egrep -c "^IPAD|^NETM" /etc/sysconfig/network-scripts/ifcfg-xenbr0`
if [ ${IPNETM} -gt 1 ] ; then
sed -i /^IPAD/d /etc/sysconfig/network-scripts/ifcfg-bond0
sed -i /^NETM/d /etc/sysconfig/network-scripts/ifcfg-bond0
sed -i /BONDING/d /etc/sysconfig/network-scripts/ifcfg-bond0
printf "BONDING_OPTS=\"mode=802.3ad miimon=200\"\n" >> /etc/sysconfig/network-scripts/ifcfg-bond0
fi

# make bond 0 bridge 0
BONDBRIDGE=`grep -c xenbr0 /etc/sysconfig/network-scripts/ifcfg-bond0`
if [ ${BONDBRIDGE} -lt 1 ] ; then
printf "BRIDGE=xenbr0\n" >> /etc/sysconfig/network-scripts/ifcfg-bond0
fi

# ensure none of them say dhcp
sed -i -e 's/dhcp/none/g' /etc/sysconfig/network-scripts/ifcfg*


for i in `seq 0 5`
do
printf "DEVICE=eth${i}\nONBOOT=yes\nTYPE=Ethernet\nSLAVE=yes\nMASTER=bond0\nHOTPLUG=no\nBOOTPROTO=none\n" > /etc/sysconfig/network-scripts/ifcfg-eth${i}
done


# this is not elegant, but much easier to see what is happening

# remap 4:0 5:1 0:2 1:3 2:4 3:5
grep Ethernet /var/log/anaconda.syslog \
 | grep "0000:0[1-3]" \
 | awk {'print $3 "," $NF'} \
 | awk -F ":" {'print $1 $2":"$3":"$4":"$5":"$6":"$7'} \
 | sed s/eth0/eth_2/g \
 | sed s/eth1/eth_3/g \
 | sed s/eth2/eth_4/g \
 | sed s/eth3/eth_5/g \
 | sed s/eth4/eth_0/g \
 | sed s/eth5/eth_1/g > /dev/shm/.tmp1

# dont make fun of me
cat /dev/shm/.tmp1 \
 | sed s/eth_2/eth2/g \
 | sed s/eth_3/eth3/g \
 | sed s/eth_4/eth4/g \
 | sed s/eth_5/eth5/g \
 | sed s/eth_0/eth0/g \
 | sed s/eth_1/eth1/g > /dev/shm/.tmp2

# this is what we will do, so leave a temp file we can make fun of
cat /dev/shm/.tmp2 | awk -F "," {'print "echo HWADDR=" $2 " >> /etc/sysconfig/network-scripts/ifcfg-" $1'} > /dev/shm/.tmp3
cat /dev/shm/.tmp3 > /root/netconfig_${TODAY}/update_mac.log

# go go go
bash /dev/shm/.tmp3

# Fix driver alias mapping in modprobe
cat /etc/modprobe.d/cobbler > /root/netconfig_${TODAY}/modprobe_cobbler.back
grep -v eth /etc/modprobe.d/cobbler > /dev/shm/.cobbler
printf "alias eth2 tg3\nalias eth3 tg3\nalias eth4 tg3\nalias eth5 tg3\nalias eth1 bnx2x\nalias eth0 bnx2x\n" > /etc/modprobe.d/cobbler
cat /dev/shm/.cobbler >> /etc/modprobe.d/cobbler

TPA=`grep -c disable_tpa /etc/modprobe.d/cobbler`
if [ ${TPA} -lt 1 ] ; then
printf "options bnx2x disable_tpa=1\n" >> /etc/modprobe.d/cobbler
fi

echo "Now you should reboot this server. 8 minutes after reboot we should have 4 interfaces and 2 LAG members in bond."

exit 0

