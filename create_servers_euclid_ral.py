#!/usr/bin/env python

import time

import openstack


IMAGE_NAME = "ScientificLinux-7-NoGui"
FLAVOR_NAME = "c1.xxlarge"
NETWORK_NAME = "euclid-private"
KEYPAIR_NAME = "euclid-saas"

VOLUME_TYPE = "rbd"
VOLUME_SIZE = 170

NODE_COUNT = 90


def get_connection():
    # openstack.enable_logging(debug=True)
    conn = openstack.connect()
    return conn


def get_or_create_server(conn, name, image, flavor, network):
    server = conn.compute.find_server(name)
    if server is None:
        server = conn.compute.create_server(
            name=name, image_id=image.id, flavor_id=flavor.id,
            networks=[{"uuid": network.id}], key_name=KEYPAIR_NAME)
        server = conn.compute.wait_for_server(server)

        volume = conn.block_storage.create_volume(name=name, volume_type="rbd", size=VOLUME_SIZE)
        conn.block_storage.wait_for_status(volume, status='available', failures=['error'], interval=2, wait=120)

        time.sleep(1)

        conn.attach_volume(server, volume)

    details = conn.compute.get_server(server.id)
    return details.addresses[NETWORK_NAME][0]['addr']


def main():
    conn = get_connection()

    image = conn.compute.find_image(IMAGE_NAME)
    if image is None:
        raise Exception("Can't find %s" % IMAGE_NAME)
    flavor = conn.compute.find_flavor(FLAVOR_NAME)
    if flavor is None:
        raise Exception("Can't find %s" % FLAVOR_NAME)
    network = conn.network.find_network(NETWORK_NAME)
    if network is None:
        raise Exception("Can't find %s" % NETWORK_NAME)

    serverAddresses = {}
    for i in range(NODE_COUNT):
	offset = 90 + i
        name = "euclid-ral_compute_%d" % offset
        serverAddresses[name] = get_or_create_server(conn, name, image, flavor, network)

    inventory_template = "[euclid-ral_compute]/n"
    for hostname, ip in serverAddresses.items():
        inventory_template += "%s ansible_host=%s" % (hostname, ip)

    print inventory_template


if __name__ == '__main__':
    main()

