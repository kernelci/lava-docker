#!/bin/sh

cd output/local

TIMEOUT=0

while [ $TIMEOUT -le 1200 ]
do
	lavacli --uri http://admin:tokenforci@127.0.0.1:10080/RPC2 devices list > devices.list
	if [ $? -eq 0 ];then
		grep -q qemu devices.list
		if [ $? -eq 0 ];then
			lavacli --uri http://admin:tokenforci@127.0.0.1:10080/RPC2 devices list
			# now wait for a job
			lavacli --uri http://admin:tokenforci@127.0.0.1:10080/RPC2 jobs list > joblist
			grep -q Running joblist
			if [ $? -eq 0 ];then
				exit 0
				lavacli --uri http://admin:tokenforci@127.0.0.1:10080/RPC2 jobs logs --no-follow 1
			else
				cat joblist
			fi
		fi
	fi
	docker-compose logs --tail=60
	docker ps > /tmp/alldocker
	grep -q master /tmp/alldocker
	if [ $? -ne 0 ];then
		echo "=========================================="
		echo "=========================================="
		echo "=========================================="
		echo "ERROR: master died"
		docker-compose logs
		exit 1
	fi
	sleep 10
	TIMEOUT=$((TIMEOUT+10))
done
exit 1
