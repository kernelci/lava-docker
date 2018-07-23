#!/bin/sh

cd $(dirname $0)
id -u > zmq_auth_gen/id
docker-compose build || exit $?
docker-compose up || exit $?
docker-compose down --rmi all
