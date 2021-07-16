#!/bin/sh

docker run busybox nslookup github.com
if [ $? -eq 0 ]; then
	echo "DEBUG: DNS query works in docker"
#	exit 0
fi

sudo echo '
{
    "dns": ["8.8.8.8"]
}' > /etc/docker/daemon.json

sudo service docker restart || exit $?
