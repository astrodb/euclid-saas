P3 Appliances
=============

A repo of tools for creating software-defined platforms for the ALaSKA P3 project.

This repo is split into two parts: 

- An Ansible Galaxy role, stackhpc.cluster-infra, which contains
  OpenStack Heat templates for creating bare metal instances configured
  for execution framework clusters.
- Ansible playbooks (including Galaxy roles) for integrating with OpenStack services, and creating 
  software middleware platforms on top of OpenStack infrastructure.

## Installation

It is recommended to install python dependencies in a virtual environment:

    virtualenv venv
    source venv/bin/activate
    pip install -U pip
    pip install -r requirements.txt

If SELinux is in use on the ansible control host, enable access to the
`selinux` python module from the virtualenv:

    ln -s /usr/lib64/python2.7/site-packages/selinux venv/lib/python2.7/site-packages/selinux

Download and deploy the role from Ansible Galaxy:

    ansible-galaxy install -r ansible/requirements.yml -p $PWD/ansible/roles

Deactivate the virtual environment:

    deactivate

## Usage

Prior to using stackhpc-appliances, ensure the virtual environment is activated:

    source venv/bin/activate

### Creating Infrastructure Using the Heat Templates

The Heat templates and stackhpc.cluster-infra role are configured locally
through YAML environment files, then invoked through the
`cluster-infra.yml` playbook.

Some example YAML template configurations are available in the `config/`
subdirectory.  To use these, some default parameters should first be
modified:

| Name | Description |
|------|-------------|
| `cluster_name`    | Name of the Heat stack to be created, and also stem of the hostnames of compute and controller nodes |
| `cluster_keypair` | An existing RSA keypair that has been previously uploaded to OpenStack |
| `cluster_groups`  | Definitions for the number of groups of compute nodes in the execution framework infrastructure, and how the compute nodes in each of those roles should be configured |

Infrastructure invocation then takes the form (for example): 

    ansible-playbook --vault-password-file vault-password -e @config/openhpc.yml -i ansible/inventory ansible/cluster-infra.yml

Once the infrastructure playbook has run to completion, an inventory
for the newly-created nodes will have been generated in the `ansible/`
subdirectory.  This inventory is suffixed with the value set in
`cluster_name`.  The cluster software can be deployed and configured
using another playbook (for example):

    ansible-playbook --vault-password-file vault-password -e @config/openhpc.yml -i ansible/inventory-openhpc ansible/openhpc.yml

### Deploying and configuring Swarm SIP

To deploy Swarm SIP cluster attached to `p3-bdn` and `p3-lln` network
interfaces, first create the cluster and generate cluster inventory and request
openstack to attach these interfaces:

    ansible-playbook --vault-password-file vault-password -i ansible/inventory -e @config/swarm-sip.yml ansible/container-infra.yml`

Then, run the second playbook to:
- Configure IB interface attached to `p3-lln` network as DHCP is not enabled
  for this interface.
- Mount the gluster volume.
- Adds public keys specified under `public_keys` folder to the authorised keys
  on the instances.

    ansible-playbook --vault-password-file=vault-password -i ansible/inventory-swarm-sip -e @config/swarm-sip.yml ansible/container-infra-configure.yml

To deploy monasca monitoring on Swarm SIP nodes, first activate cluster config:

    $(mkdir -p swarm-sip && openstack coe cluster config swarm-sip --force --dir=swarm-sip)

Then, run the monitoring deployment playbook:

    ansible-playbook --vault-password-file vault-password -i ansible/inventory -e @config/swarm-sip.yml ansible/monitoring-monasca-container.yml`

### Dedicated GlusterFS/BeeGFS Storage

Creating gluster storage cluster infrastructure using storage-A (nvme) and storage-B (ssd) flavours:

    ansible-playbook --vault-password-file vault-password -e @config/storage-ssd.yml -i ansible/inventory ansible/cluster-infra.yml
    ansible-playbook --vault-password-file vault-password -e @config/storage-nvme.yml -i ansible/inventory ansible/cluster-infra.yml

Configuring openhpc and storage nodes to share common hostname namespace:

    ansible-playbook --vault-password-file vault-password -i ansible/inventory-openhpc -i ansible/inventory-storage-nvme -i ansible/inventory-storage-ssd ansible/setup.yml

To setup BeeGFS server:

    ansible-playbook --vault-password-file vault-password -e @config/storage-ssd.yml -i ansible/inventory-storage-ssd ansible/beegfs.yml
    ansible-playbook --vault-password-file vault-password -e @config/storage-nvme.yml -i ansible/inventory-storage-nvme ansible/beegfs.yml

NOTES:
- Add `-e beegfs_force_format=yes` option to force disk to be formatted if it is being used for something else or not empty
- Add `-e beegfs_state=absent` option to destroy node

To setup GlusterFS server:

    ansible-playbook --vault-password-file vault-password -e @config/storage-ssd.yml -i ansible/inventory-storage-ssd ansible/glusterfs.yml
    ansible-playbook --vault-password-file vault-password -e @config/storage-nvme.yml -i ansible/inventory-storage-nvme ansible/glusterfs.yml

To setup hyperconverged storage and mount storage on OpenHPC node:

    ansible-playbook --vault-password-file vault-password -e @config/openhpc.yml -i ansible/inventory-openhpc ansible/openhpc.yml
