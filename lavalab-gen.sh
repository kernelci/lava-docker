#!/bin/sh

rm -rf output

if [ "$1" = "mrproper" ];then
	exit 0
fi

./lavalab-gen.py $* || exit 1
