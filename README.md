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

`ln -s /usr/lib64/python2.7/site-packages/selinux venv/lib/python2.7/site-packages/selinux`

Download and deploy the role from Ansible Galaxy:

`ansible-galaxy install -r ansible/requirements.yml -p $PWD/ansible/roles`

Deactivate the virtual environment:

`deactivate`

## Usage

Prior to using stackhpc-appliances, ensure the virtual environment is activated:

`source venv/bin/activate`

### Creating Infrastructure Using the Heat Templates

The Heat templates and stackhpc.cluster-infra role are configured locally
through YAML environment files, then invoked through the
`cluster-infra.yml` playbook.

Some example YAML template configurations are available in the `config/`
subdirectory.  To use these, some default parameters should first be
modified:

| Name | Description |
|------|-------------|
| `cluster_name` | Name of the Heat stack to be created, and also stem of the hostnames of compute and controller nodes |
| `cluster_keypair` | An existing RSA keypair that has been previously uploaded to OpenStack |
| `cluster_groups` | Definitions for the number of groups of compute nodes in the execution framework infrastructure, and how the compute nodes in each of those roles should be configured |

Infrastructure invocation then takes the form (for example): 

`ansible-playbook -e @config/openhpc.yml -i ansible/inventory ansible/cluster-infra.yml`

Once the infrastructure playbook has run to completion, an inventory
for the newly-created nodes will have been generated in the `ansible/`
subdirectory.  This inventory is suffixed with the value set in
`cluster_name`.  The cluster software can be deployed and configured
using another playbook (for example):

`ansible-playbook -e @config/openhpc.yml -i ansible/inventory_openhpc ansible/openhpc.yml`

