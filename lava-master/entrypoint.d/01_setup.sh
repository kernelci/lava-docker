#!/bin/bash

# always reset the lavaserver user, since its password could have been reseted in a "docker build --nocache"
if [ ! -e /root/pg_lava_password ];then
       < /dev/urandom tr -dc A-Za-z0-9 | head -c16 > /root/pg_lava_password
fi
sudo -u postgres psql -c "ALTER USER lavaserver WITH PASSWORD '$(cat /root/pg_lava_password)';" || exit $?
sed -i "s,^LAVA_DB_PASSWORD=.*,LAVA_DB_PASSWORD='$(cat /root/pg_lava_password)'," /etc/lava-server/instance.conf || exit $?

if [ -e /root/backup/db_lavaserver.gz ];then
	gunzip /root/backup/db_lavaserver.gz || exit $?
fi

if [ -e /root/backup/db_lavaserver ];then
	echo "Restore database from backup"
	sudo -u postgres psql < /root/backup/db_lavaserver || exit $?
	yes yes | lava-server manage migrate || exit $?
	echo "Restore jobs output from backup"
	rm -r /var/lib/lava-server/default/media/job-output/*
	tar xzf /root/backup/joboutput.tar.gz || exit $?
fi

if [ -e /root/backup/devices.tar.gz ];then
	echo "INFO: Restoring devices files"
	tar xzf /root/backup/devices.tar.gz
	chown -R lavaserver:lavaserver /etc/lava-server/dispatcher-config/devices
fi

chown -R lavaserver:lavaserver /var/lib/lava-server/default/media/job-output/

# default site is set as example.com
if [ -e /root/lava_http_fqdn ];then
	sudo -u postgres psql lavaserver -c "UPDATE django_site SET name = '$(cat /root/lava_http_fqdn)'" || exit $?
	sudo -u postgres psql lavaserver -c "UPDATE django_site SET domain = '$(cat /root/lava_http_fqdn)'" || exit $?
fi

if [ -e /root/lava-users ];then
	for ut in $(ls /root/lava-users)
	do
		# User is the filename
		USER=$ut
		USER_OPTION=""
		STAFF=0
		SUPERUSER=0
		TOKEN=""
		. /root/lava-users/$ut
		if [ -z "$PASSWORD" -o "$PASSWORD" = "$TOKEN" ];then
			echo "Generating password..."
			#Could be very long, should be avoided
			PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
		fi
		if [ $STAFF -eq 1 ];then
			USER_OPTION="$USER_OPTION --staff"
		fi
		if [ $SUPERUSER -eq 1 ];then
			USER_OPTION="$USER_OPTION --superuser"
		fi
		lava-server manage users list --all > /tmp/allusers
		if [ $? -ne 0 ];then
			echo "ERROR: cannot generate user list"
			exit 1
		fi
		#filter first name/last name (enclose by "()")
		sed -i 's,[[:space:]](.*$,,' /tmp/allusers
		grep -q "[[:space:]]${USER}$" /tmp/allusers
		if [ $? -eq 0 ];then
			echo "Skip already existing $USER DEBUG(with $TOKEN / $PASSWORD / $USER_OPTION)"
		else
			echo "Adding username $USER DEBUG(with $TOKEN / $PASSWORD / $USER_OPTION)"
			lava-server manage users add --passwd $PASSWORD $USER_OPTION $USER
			if [ $? -ne 0 ];then
				echo "ERROR: Adding user $USER"
				cat /tmp/allusers
				exit 1
			fi
			if [ ! -z "$TOKEN" ];then
				echo "Adding token to user $USER"
				lava-server manage tokens add --user $USER --secret $TOKEN || exit 1
			fi
			if [ ! -z "$EMAIL" ];then
				echo "Adding email to user $USER"
				lava-server manage users update --email $EMAIL $USER || exit 1
			fi
		fi
	done
fi

if [ -e /root/lava-groups ];then
	echo "======================================================"
	echo "Handle groups"
	echo "======================================================"
	GROUP_CURRENT_LIST=/tmp/group.list
	lava-server manage groups list > ${GROUP_CURRENT_LIST}.raw || exit 1
	grep '^\*' ${GROUP_CURRENT_LIST}.raw > ${GROUP_CURRENT_LIST}
	for group in $(ls /root/lava-groups/*group)
	do
		GROUPNAME=""
		SUBMIT=0
		OPTION_SUBMIT=""
		. $group
		grep -q $GROUPNAME $GROUP_CURRENT_LIST
		if [ $? -eq 0 ];then
			echo "DEBUG: SKIP creation of $GROUPNAME which already exists"
		else
			if [ $SUBMIT -eq 1 ];then
				echo "DEBUG: $GROUPNAME can submit jobs"
				OPTION_SUBMIT="--submitting"
			fi
			echo "DEBUG: Add group $GROUPNAME"
			lava-server manage groups add $OPTION_SUBMIT $GROUPNAME || exit 1
		fi
		if [ -e ${group}.list ];then
			echo "DEBUG: Found ${group}.list"
			while read username
			do
				echo "DEBUG: Add user $username to group $GROUPNAME"
				lava-server manage groups update --username $username $GROUPNAME || exit 1
			done < ${group}.list
		fi
	done
fi

if [ -e /root/lava-callback-tokens ];then
	for ct in $(ls /root/lava-callback-tokens)
	do
		. /root/lava-callback-tokens/$ct
		if [ -z "$USER" ];then
			echo "Missing USER"
			exit 1
		fi
		if [ -z "$TOKEN" ];then
			echo "Missing TOKEN for $USER"
			exit 1
		fi
		if [ -z "$DESCRIPTION" ];then
			echo "Missing DESCRIPTION for $USER"
			exit 1
		fi
		lava-server manage tokens list --user $USER |grep -q $TOKEN
		if [ $? -eq 0 ];then
			echo "SKIP already present token for $USER"
		else
			echo "Adding $USER ($DESCRIPTION) DEBUG($TOKEN)"
			lava-server manage tokens add --user $USER --secret $TOKEN --description "$DESCRIPTION" || exit 1
		fi
	done
fi

# This directory is used for storing device-types already added
mkdir -p /root/.lavadocker/
if [ -e /root/device-types ];then
	for i in $(ls /root/device-types/*jinja2)
	do
		if [ -e /etc/lava-server/dispatcher-config/device-types/$(basename $i) ];then
			echo "WARNING: overwriting device-type $i"
			diff -u "/etc/lava-server/dispatcher-config/device-types/$(basename $i)" $i
		fi
		cp $i /etc/lava-server/dispatcher-config/device-types/
		chown lavaserver:lavaserver /etc/lava-server/dispatcher-config/device-types/$(basename $i)
		devicetype=$(basename $i |sed 's,.jinja2,,')
		lava-server manage device-types list | grep -q "[[:space:]]$devicetype[[:space:]]"
		if [ $? -eq 0 ];then
			echo "Skip already known $devicetype"
		else
			echo "Adding custom $devicetype"
			lava-server manage device-types add $devicetype || exit $?
			touch /root/.lavadocker/devicetype-$devicetype
		fi
	done
fi

for worker in $(ls /root/devices/)
do
	echo "Adding worker $worker"
	lava-server manage workers add $worker || exit $?
	for device in $(ls /root/devices/$worker/)
	do
		devicename=$(echo $device | sed 's,.jinja2,,')
		devicetype=$(grep -h extends /root/devices/$worker/$device| grep -o '[a-zA-Z0-9_-]*.jinja2' | sed 's,.jinja2,,')
		if [ -e /root/.lavadocker/devicetype-$devicetype ];then
			echo "Skip devicetype $devicetype"
		else
			echo "Add devicetype $devicetype"
			lava-server manage device-types add $devicetype || exit $?
			touch /root/.lavadocker/devicetype-$devicetype
		fi
		echo "Add device $devicename on $worker"
		cp /root/devices/$worker/$device /etc/lava-server/dispatcher-config/devices/ || exit $?
		lava-server manage devices add --device-type $devicetype --worker $worker $devicename || exit $?
	done
done

if [ -e /etc/lava-dispatcher/certificates.d/$(hostname).key ];then
	echo "INFO: Enabling encryption"
	sed -i 's,.*ENCRYPT=.*,ENCRYPT="--encrypt",' /etc/lava-server/lava-master || exit $?
	sed -i 's,.*MASTER_CERT=.*,MASTER_CERT="--master-cert /etc/lava-dispatcher/certificates.d/$(hostname).key_secret",' /etc/lava-server/lava-master || exit $?
	sed -i 's,.*ENCRYPT=.*,ENCRYPT="--encrypt",' /etc/lava-server/lava-logs || exit $?
	sed -i 's,.*MASTER_CERT=.*,MASTER_CERT="--master-cert /etc/lava-dispatcher/certificates.d/$(hostname).key_secret",' /etc/lava-server/lava-logs || exit $?
fi
exit 0
