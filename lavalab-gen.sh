#!/bin/sh

rm -f lava-master/scripts/build-lava
rm -f lava-slave/scripts/build-lava
rm -rf output

if [ "$1" = "mrproper" ];then
	exit 0
fi

./lavalab-gen.py || exit 1
