#!/usr/bin/env python

import xmlrpclib
import sys

if len(sys.argv) < 4:
    print("ERROR: Usage: %s URI workername dispatcherIP" % sys.argv[0])
    sys.exit(1)

server = xmlrpclib.ServerProxy("%s" % sys.argv[1])
server.scheduler.workers.set_config("%s" % sys.argv[2], "dispatcher_ip: %s" % sys.argv[3])
