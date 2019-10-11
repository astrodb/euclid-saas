#! /usr/bin/env python

import json
import sys


blob = json.load(sys.stdin)
blob_byid = { x['id']: x for x in blob['nodes'] }
blob_hosts = [ x for x in blob['nodes'] if x['type']=="host" ]

for host in blob_hosts:
    print ("%s %s" % (host['name'], ' '.join([str(child) for child in host['children']])))
