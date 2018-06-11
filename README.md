P3 Appliances
=============

A repo of tools for creating software-defined platforms for the ALaSKA P3 project.

This repo is split into two parts: 

- An Ansible Galaxy role, stackhpc.cluster-infra, which contains
  OpenStack Heat templates for creating bare metal instances configured
  for execution framework clusters.
- Ansible playbooks for integrating with OpenStack services, and creating 
  software middleware platforms on top of ALaSKA infrastructure.

Installation
------------

Initialise a Python 2.7 virtual environment,

```
sudo yum install python-virtualenv libselinux-python
virtualenv --system-site-packages ~/ansible-venv
source ~/ansible-venv/bin/activate
pip install -r requirements.txt
```

Then, download and deploy the role from Ansible Galaxy:

```
(cd ansible && ansible-galaxy install -r requirements.yml -p $PWD/roles)
```

Creating Infrastructure Using the Heat Templates
------------------------------------------------

The Heat templates and stackhpc.cluster-infra role are configured locally
through YAML environment files, then invoked through the
`alaska-infra.yml` playbook.

Some example YAML template configurations are available in the `config/`
subdirectory.  To use these, some default parameters should first be
modified:

| Name | Description |
|------|-------------|
| `cluster_name`    | Name of the Heat stack to be created, and also stem of the hostnames of compute and controller nodes |
| `cluster_keypair` | An existing RSA keypair that has been previously uploaded to OpenStack |
| `cluster_groups`  | Definitions for the number of groups of compute nodes in the execution framework infrastructure, and how the compute nodes in each of those roles should be configured |

Infrastructure invocation then takes the form (for example): 

`ansible-playbook -e @config/openhpc.yml -i ansible/inventory --vault-password-file=vault-password ansible/cluster-infra.yml`

Once the infrastructure playbook has run to completion, an inventory
for the newly-created nodes will have been generated in the `ansible/`
subdirectory.  This inventory is suffixed with the value set in
`cluster_name`.  The cluster software can be deployed and configured
using another playbook (for example):

`ansible-playbook -e @config/openhpc.yml -i ansible/inventory_openhpc --vault-password-file=vault-password ansible/openhpc.yml`

Deploying and configuring Swarm SIP
-----------------------------------

To deploy Swarm SIP cluster attached to `p3-bdn` and `p3-lln` network
interfaces, first create the cluster and generate cluster inventory and request
openstack to attach these interfaces:

```
ansible-playbook -i ansible/inventory --vault-password-file=vault-password ansible/deploy_container_infra.yml 
```

Then, run the second playbook to:
- Configure IB interface attached to `p3-lln` network as DHCP is not enabled
  for this interface.
- Mount the gluster volume.
- Adds public keys specified under `public_keys` folder to the authorised keys
  on the instances.

```
ansible-playbook -i ansible/inventory-swarm-sip --vault-password-file=vault-password ansible/configure_container_infra.yml 
```

To deploy monasca monitoring on SIP nodes, first activate cluster config:

```
$(mkdir -p swarm-sip && openstack coe cluster config swarm-sip --force --dir=swarm-sip)
ansible-playbook -i ansible/inventory --valult-password-file=vault-password ansible/deploy_monasca_swarm_monitoring.yml
```

