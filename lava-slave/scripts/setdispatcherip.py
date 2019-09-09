#!/usr/bin/env python3

import xmlrpc.client
import sys

if len(sys.argv) < 4:
    print("ERROR: Usage: %s URI workername dispatcherIP" % sys.argv[0])
    sys.exit(1)

server = xmlrpc.client.ServerProxy("%s" % sys.argv[1])
server.scheduler.workers.set_config("%s" % sys.argv[2], "dispatcher_ip: %s" % sys.argv[3])
