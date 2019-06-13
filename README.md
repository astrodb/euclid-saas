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

You should also source the credentials for the OpenStack cloud you are
targeting, usually of the form:

    source openrc.sh

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

### Infrastructure Setup - Configuration and Customisation

After infrastructure has been successfully created, Ansible inventory
files are generated for the new infrastructure, and SSH host keys are
scanned and pre-loaded into the Ansible user's `known_hosts` file.
This enables platform configuration to proceed using Ansible playbooks.

From an approximately equivalent CentOS base image, some configuration
common to all platforms is applied, and some specific to each platform.
We must also perform site-specific configuration to account for any
differences in infrastructure, software image or environment at each site.

Both of the above are taken care of through invocation of the `setup.yml`
playbook, which is now called with the inventories from all sites:

```
ansible-playbook -i ansible/inventory-euclid-edi \
                 -i ansible/inventory-euclid-cam \
                 -i ansible/inventory-euclid-ral \
                 -i ansible/inventory-euclid-sausage \
                 ansible/setup.yml
```

We then create the OpenVPN connections to configure an IP-routed mesh
between all sites:

```
ansible-playbook -i ansible/inventory-euclid-edi \
                 -i ansible/inventory-euclid-cam \
                 -i ansible/inventory-euclid-ral \
                 -i ansible/inventory-euclid-sausage \
                 ansible/openvpn.yml
```

### Deployment of Federated Ceph

The [https://github.com/astrodb/euclid-ceph-ansible](Euclid
Ceph-Ansible repo) is required.  We are working from the `euclid-3.2`
branch.

Create a directory called `euclid` in `euclid-ceph-ansible`.
Transfer the Ansible inventory files to the `euclid` directory.
Transfer `ansible/group_vars` to the `euclid` directory.

A separate python virtualenv is required for Ceph-Ansible, because the
`euclid-3.2` branch has a conflicting (older) dependency constraint on
the version of Ansible to use.

```
cd euclid-ceph-ansible
virtualenv venv
source venv/bin/activate
pip install -U pip
pip install -r requirements.txt
```

Invocation of Ceph-Ansible is as follows:

```
ansible-playbook -i euclid site.yml
```

... It can take a while to work through.

#### Post-deployment Ceph Configuration

Some functionality is not deployed with in the current `site.yml` playbook.

- Update crush rules for the existing pools.
  Run as `root` from a Ceph monitor.
```
ceph osd pool set euclid_cam crush_rule replicated_cam
ceph osd pool set euclid_ral crush_rule replicated_ral
ceph osd pool set euclid_sausage crush_rule replicated_sausage
```

- Ceph FS fixup with additional data pools:
  Run as `root` from a Ceph monitor.
```
ceph fs add_data_pool cephfs euclid_cam
ceph fs add_data_pool cephfs euclid_ral
ceph fs add_data_pool cephfs euclid_sausage
```

- Mount the Ceph filesystem on all clients.
  Run from the Ansible control host.
```
ansible-playbook -i euclid euclid-mount.yml 
```

- Create directories linked to regional storage pools.
  Run as `root` from a Ceph monitor.
```
cd /ceph
mkdir home ral cam sausage
setfattr -n ceph.dir.layout.pool -v euclid_cam cam
setfattr -n ceph.dir.layout.pool -v euclid_ral ral
setfattr -n ceph.dir.layout.pool -v euclid_sausage sausage
```

### Adding Users to Euclid

Euclid platform users are defined in `ansible/group_vars/all/users`

*NOTE*: This playbook appears to hit SELinux snags which may be due
to CephFS not supporting SELinux, and the non-standard location for
Euclid home directories.

Run the playbook first at a site (eg RAL) where SELinux is off by
default, and then run again on all sites.  Ansible idempotency will
ensure that all required operations happen once everywhere.

```
ansible-playbook -i ansible/inventory-euclid-ral \
                 -i ansible/inventory-euclid-edi \
                 -i ansible/inventory-euclid-cam \
                 -i ansible/inventory-euclid-sausage \
                 ansible/euclid-users.yml  
```

### Deploying CERNVMFS and Mounting Euclid Repos

This play will deploy Squid HTTP proxy servers at every site.
The servers that will take this role are defined in the 
`cluster_cvmfs_proxy` group in the Ansible inventory. 

The Squid proxy will also be used as a local cache for Yum
package updates.

```
ansible-playbook -i ansible/inventory-euclid-ral \
                 -i ansible/inventory-euclid-edi \
                 -i ansible/inventory-euclid-cam \
                 -i ansible/inventory-euclid-sausage \
                 -e @config/euclid-compute.yml \
                 ansible/euclid-cvmfs.yml  
```

### Deploying OpenHPC and Slurm

The Slurm and base HPC runtime is deployed at all sites using
OpenHPC.  A Slurm configuration is generated with the compute
nodes for each site placed into a dedicated partition.

```
ansible-playbook -i ansible/inventory-euclid-ral \
                 -i ansible/inventory-euclid-edi \
                 -i ansible/inventory-euclid-cam \
                 -i ansible/inventory-euclid-sausage \
                 -e @config/euclid-compute.yml \
                 ansible/euclid-openhpc.yml  
```

### Using Slurm

OpenHPC uses LMOD for loading different variants and versions of
system libraries.  For example:

```
module load gnu7 openmpi3 imb
srun  -p cam -N 2 --mpi=pmix IMB-MPI1 PingPong
```
