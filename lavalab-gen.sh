#!/bin/sh

rm -r output
rm -rv lava-master/slaves/
rm -rv lava-master/tokens/
rm -rv lava-master/users/
rm lava-master/scripts/build-lava
rm lava-slave/scripts/build-lava

if [ "$1" = "mrproper" ];then
	exit 0
fi

./lavalab-gen.py || exit 1
