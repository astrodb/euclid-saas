Euclid-as-a-Service
===================

A repo of tools for creating software-defined platforms for the Euclid project
for deployment on IRIS federated OpenStack infrastructure (https://www.iris.ac.uk/).

This repo is split into two parts: 

- An Ansible Galaxy role, stackhpc.cluster-infra, which contains
  OpenStack Heat templates for creating bare metal instances configured
  for execution framework clusters.
- Ansible playbooks (including Galaxy roles) for integrating with OpenStack services, and creating 
  software middleware platforms on top of OpenStack infrastructure.

## Installation

It is recommended to install python dependencies in a virtual environment:

    virtualenv venv --system-site-packages
    source venv/bin/activate
    pip install -U pip
    pip install -r requirements.txt --upgrade

Download and deploy the role from Ansible Galaxy:

    ansible-galaxy install -r ansible/requirements.yml -p $PWD/ansible/roles

It is also worthwhile to run an SSH agent, and load it with your deploy key:

    eval $(ssh-agent)
    ssh-add ~/.ssh/id_euclid

When you're done, deactivate the virtual environment after completion of
deployment activities:

    deactivate

## Usage

Prior to using euclid-saas, ensure the virtual environment is activated:

    source venv/bin/activate

### Euclid IRIS Infrastructures

IRIS infrastructure is available at a number of participating sites across
the UK.  At each site, an OpenStack API must be reachable, and certain
key portability parameters must be known.  These parameters are codified
in the inventories and group variables of this repo.

To access OpenStack APIs at different sites, either source the `openrc`
file provided by that site, or deinfe the authentication parameters in
a `clouds.yaml` file that can be accessed by the OpenStack client SDKs.

### Creating Infrastructure Using the Heat Templates

The Heat templates and stackhpc.cluster-infra role are configured locally
through YAML environment files, then invoked through the
`cluster-infra.yml` playbook.

Some example YAML template configurations are available in the `config/`
subdirectory.

  * `eucild-aio.yml` is an all-in-one deployment of all components of the
    Euclid platform.
  * `eucild-compute.yml` is infrastructure for a federated compute
    partition.

To create compute infrastructure at different sites, first source the
credentials for the site, and then invoke the appropriate inventory:

| Name | Description |
|------|-------------|
| `cluster_keypair` | An existing RSA keypair that has been previously uploaded to OpenStack |

Infrastructure invocation then takes the form (for example): 

```
ansible-playbook -i ansible/infra-ral \
    ansible/cluster-infra.yml \
    -e @config/euclid-compute.yml \
    -e cluster_keypair=euclid
```

