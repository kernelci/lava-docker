#!/bin/sh

rm -rv lava-master/devices/
rm -rv lava-master/slaves/
rm -rv lava-slave/conmux/
rm -rv lava-master/tokens/
rm -rv lava-master/users/
rm *lavalab*rules

if [ "$1" = "mrproper" ];then
	exit 0
fi

./lavalab-gen.py || exit 1

rm /etc/udev/rules.d/*lavalab*rules
cp *lavalab*rules /etc/udev/rules.d/

docker-compose build || exit 1
docker-compose up || exit 1
