#!/bin/bash
# Set LAVA Master IP
if [[ -n "$LAVA_MASTER" ]]; then
	sed -i -e "s/{LAVA_MASTER}/$LAVA_MASTER/g" /etc/lava-dispatcher/lava-slave
fi

service tftpd-hpa start || exit 4

# FIXME lava-slave does not run if old pid is present
rm -f /var/run/lava-slave.pid
service lava-slave start || exit 5

# start an http file server for boot/transfer_overlay support
(cd /var/lib/lava/dispatcher; python -m SimpleHTTPServer 80)
