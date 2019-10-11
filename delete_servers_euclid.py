#!/usr/bin/env python
import time
import openstack
NODE_COUNT = 43
def get_connection():
    # openstack.enable_logging(debug=True)
    conn = openstack.connect()
    return conn
def main():
    conn = get_connection()
    for i in range(NODE_COUNT):
        name = "euclid-ral_compute_%d" % i
        conn.delete_server(name, wait=True)
    for i in range(NODE_COUNT):
        name = "euclid-ral_compute_%d" % i
        conn.delete_volume(name, wait=True)
    
if __name__ == '__main__':
    main()
