#!/bin/bash

if [ -e /var/run/squid.pid ];then
	#echo "DEBUG: Removed old squid PID"
	rm /var/run/squid.pid
fi

# Create cache FS
if [ ! -e /var/spool/squid/00 ];then
	squid -z || exit $?
fi
/usr/sbin/squid -NYC -f /etc/squid/squid.conf || exit $?
