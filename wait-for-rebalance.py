#! /usr/bin/env python

import json
import sys


blob = json.load(sys.stdin)
result = 0

for pool in blob:
    if 'misplaced_objects' in pool['recovery'] and pool['recovery']['misplaced_objects'] > 0:
        print ("%s %d" % (pool['pool_name'], pool['recovery']['misplaced_objects']))
	result = result + 1

sys.exit(result)
