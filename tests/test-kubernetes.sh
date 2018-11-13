#!/bin/bash

set -e

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd ${PARENT}/..

function usage {
    echo "Usage"
    echo "$0 [create|destroy]"
}

if [[ $OS_CLOUD == "alaska" ]]; then
    INVENTORY=inventory
elif [[ $OS_CLOUD == "alaska-alt-1" ]]; then
    INVENTORY=inventory-alt-1
else
    echo "Set OS_CLOUD to either 'alaska' or 'alaska-alt-1'"
    exit 1
fi

STATE=present
if [[ $# -eq 1 ]]; then
    if [[ $1 = destroy ]]; then
        STATE=absent
    elif [[ $1 != create ]]; then
        usage
        exit 1
    fi
elif [[ $# -ne 0 ]]; then
    usage
    exit 1
fi

# Deploy infrastructure.
ansible-playbook \
--vault-password-file /opt/alaska/vault-password \
-e @config/kubernetes.yml \
-e @config/test-kubernetes.yml \
-e os_container_infra_state=$STATE \
-i ansible/$INVENTORY \
ansible/container-infra.yml

if [[ $STATE != absent ]]; then
    # Configure.
    ansible-playbook \
    --vault-password-file /opt/alaska/vault-password \
    -e @config/kubernetes.yml \
    -e @config/test-kubernetes.yml \
    -i ansible/inventory-test-kubernetes \
    ansible/container-infra-configure.yml
fi
