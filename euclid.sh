#!/bin/bash

set -e

ansible-playbook \
-i ansible/inventory_euc -i ansible/inventory_euc-2 \
-e @config/euclid.yml \
-e ansible_ssh_private_key_file=~/wendy_house/id_wendy \
--forks 250 \
$@
