#!/bin/sh

BACKUP_DIR="backup-$(date +%Y%m%d_%H%M)"

mkdir $BACKUP_DIR
cp boards.yaml $BACKUP_DIR

DOCKERID=$(docker ps |grep master | cut -d' ' -f1)
if [ -z "$DOCKERID" ];then
	exit 1
fi
# for an unknown reason pg_dump > file doesnt work
docker exec -ti $DOCKERID sudo -u postgres pg_dump --create --clean lavaserver --file /tmp/db_lavaserver || exit $?
docker exec -ti $DOCKERID gzip /tmp/db_lavaserver || exit $?
docker cp $DOCKERID:/tmp/db_lavaserver.gz $BACKUP_DIR/ || exit $?
docker exec -ti $DOCKERID rm /tmp/db_lavaserver.gz || exit $?

docker exec -ti $DOCKERID tar czf /root/joboutput.tar.gz /var/lib/lava-server/default/media/job-output/ || exit $?
docker cp $DOCKERID:/root/joboutput.tar.gz $BACKUP_DIR/ || exit $?
docker exec -ti $DOCKERID rm /root/joboutput.tar.gz || exit $?

echo "Backup done in $BACKUP_DIR"
