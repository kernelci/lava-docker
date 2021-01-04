#!/usr/bin/env python3

import xmlrpc.client
import sys

if len(sys.argv) < 3:
    print("ERROR: Usage: %s URI workername" % sys.argv[0])
    sys.exit(1)

server = xmlrpc.client.ServerProxy("%s" % sys.argv[1])
wdet = server.scheduler.workers.show("%s" % sys.argv[2])
if "token" in wdet:
    print(wdet["token"])
    sys.exit(0)
sys.exit(1)
