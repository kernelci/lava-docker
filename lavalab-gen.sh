#!/bin/sh

rm lava-master/scripts/build-lava
rm lava-slave/scripts/build-lava
rm -r output

if [ "$1" = "mrproper" ];then
	exit 0
fi

./lavalab-gen.py || exit 1
