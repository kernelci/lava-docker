#!/bin/bash

# Create cache FS
if [ ! -e /var/spool/squid/00 ];then
	squid -z || exit $?
fi
/usr/sbin/squid -NYC -f /etc/squid/squid.conf || exit $?
