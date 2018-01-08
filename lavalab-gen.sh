#!/bin/sh

rm -rv lava-master/devices/
rm -rv lava-master/slaves/
rm -rv lava-slave/conmux/
rm -rv lava-master/tokens/
rm -rv lava-master/users/
rm lavalab*rules

if [ "$1" = "mrproper" ];then
	exit 0
fi

./lavalab-gen.py || exit 1

#check for root
BEROOT=""
if [ $(id -u) -ne 0 ];then
	BEROOT="sudo "
fi
$BEROOT rm /etc/udev/rules.d/*lavalab*rules
$BEROOT cp *lavalab*rules /etc/udev/rules.d/
$BEROOT udevadm control --reload-rules || exit $?
$BEROOT udevadm trigger || exit $?

docker-compose build || exit 1
docker-compose up || exit 1
