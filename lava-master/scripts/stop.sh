#!/bin/bash

service lava-master stop
service lava-slave stop
service lava-logs stop
service lava-coordinator stop
service lava-server-gunicorn stop
service apache2 stop
/etc/init.d/postgresql stop
service tftpd-hpa stop
