#!/bin/sh
# By Jr simple firewall

IPTABLES=`wich iptables`
LOCAL=/opt/firewall
OPEN=$LOCAL/open.txt
BLOCK=$LOCAL/block.txt
ALLOWED=$LOCAL/port.txt
#ALLOWED="21,80"

# color
txtred='\e[0;31m'
txtblue='\e[0;34m'
txtgrn='\e[0;32m'
txtylw='\e[0;33m'
txtrst='\e[0m'

blue() {
	echo -e "${txtblue}$*${txtrst}"
}

red() {
	echo -e "${txtred}$*${txtrst}"
}

set_proc() {
	echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route 
	echo 0 > /proc/sys/net/ipv4/conf/all/accept_redirects 
	echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
	echo 1 > /proc/sys/net/ipv4/tcp_syncookies 
	echo 1 > /proc/sys/net/ipv4/conf/default/rp_filter 
}

clear_rules() {
	$IPTABLES -F
	red 'Clearing Tables F'
	$IPTABLES -X
	red 'Clearing Tables X'
	$IPTABLES -Z
	red 'Clearing Tables Z'

	$IPTABLES -F
	$IPTABLES -X
	$IPTABLES -t mangle -F
	$IPTABLES -P INPUT ACCEPT
	$IPTABLES -P OUTPUT ACCEPT
	$IPTABLES -P FORWARD ACCEPT
}

fw_start() {

	set_proc

	$IPTABLES -A INPUT -m state --state INVALID -j DROP

	echo "Permitting Localhost"
	$IPTABLES -A INPUT -t filter -s 127.0.0.1 -j ACCEPT

	for LINE in `grep -v ^# $OPEN | awk '{print $1}'`; do
		echo "Permitting $LINE..."
		$IPTABLES -A INPUT -t filter -s $LINE -j ACCEPT
	done

	for LINE in `grep -v ^# $BLOCK | awk '{print $1}'`; do
		echo "Denying $LINE..."
		$IPTABLES -A INPUT -t filter -s $LINE -j DROP
	done

	for PORT in $ALLOWED; do
		echo "Accepting port TCP $PORT..."
		$IPTABLES -A INPUT -t filter -p tcp --dport $PORT -j ACCEPT
	done

	for PORT in $ALLOWED; do
		echo "Accepting port UDP $PORT..."
		$IPTABLES -A INPUT -t filter -p udp --dport $PORT -j ACCEPT
	done

	$IPTABLES -A INPUT -p udp -j DROP
	$IPTABLES -A INPUT -p tcp --syn -j DROP
}

fw_stop() {
	red "Stop firewall" 
	#rm -rf /var/lock/subsys/firewall
	clear_rule
}

fw_status() {
	blue "Ports Allowed"
	cat $ALLOWED

	blue "Ips Allowed"
	cat $OPEN

	blue "$red Ips Deny"
	cat $BLOCK

	blue "Iptables"
	$IPTABLES -L
}
 
 
usage() {
	echo "Usage:"
	echo "$0 {start|stop|status|restart|reload}"
}

case "$1" in
	start)
		fw_start
	;;
	
	stop)
		fw_stop
	;;

	restart)
		fw_stop
		fw_start
	;;

	status)
		fw_status
	;;

	*)
		usage
	;;
esac

exit 0
