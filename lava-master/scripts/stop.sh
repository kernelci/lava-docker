#!/bin/bash

service lava-master stop
service lava-slave stop
service lava-server stop
service lava-coordinator stop
service lava-server-gunicorn stop
service apache2 stop
service postgresql stop
service tftpd-hpa stop
