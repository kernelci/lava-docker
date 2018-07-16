#!/bin/bash

/setup.sh || exit $?

# Set LAVA Master IP
if [[ -n "$LAVA_MASTER" ]]; then
	sed -i -e "s/{LAVA_MASTER}/$LAVA_MASTER/g" /etc/lava-dispatcher/lava-slave
fi

service tftpd-hpa start || exit 4
if [ -s /etc/ser2net.conf ];then
	service ser2net start || exit 7
fi

touch /var/run/conmux-registry
/usr/sbin/conmux-registry 63000 /var/run/conmux-registry&
sleep 2
for item in $(ls /etc/conmux/*cf)
do
	echo "Add $item"
	# On some OS, the rights/user from host are not duplicated on guest
	grep -o '/dev/[a-zA-Z0-9_-]*' $item | xargs chown uucp
	/usr/sbin/conmux $item &
done

HAVE_SCREEN=0
while read screenboard
do
	echo "Start screen for $screenboard"
	TERM=xterm screen -d -m -S $screenboard /dev/$screenboard 115200 -ixoff -ixon || exit 9
	HAVE_SCREEN=1
done < /root/lava-screen.conf
if [ $HAVE_SCREEN -eq 1 ];then
	sed -i 's,UsePAM.*yes,UsePAM no,' /etc/ssh/sshd_config || exit 10
	service ssh start || exit 11
fi


# start an http file server for boot/transfer_overlay support
(cd /var/lib/lava/dispatcher; python -m SimpleHTTPServer 80) &

# FIXME lava-slave does not run if old pid is present
rm -f /var/run/lava-slave.pid
service lava-slave start || exit 5

sleep 3650d
