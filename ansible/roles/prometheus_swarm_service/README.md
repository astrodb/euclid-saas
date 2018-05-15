Prometheus Swarm monitoring service
===================================

This role assumes the following environment variables have been set
in order to interact with the target Swarm Docker API.

* `DOCKER_HOST`
* `DOCKER_CERT_PATH`
* `DOCKER_TLS_VERIFY`

A script to set these can be generated from the OpenStack CLI:

`mkdir -p ~/swarm-creds && $(openstack coe cluster config <cluster name> --dir ~/swarm-creds --force | tee ~/swarm-creds/env.sh)`

This role currently makes no attempt to configure the Prometheus server to scrape
the Swarm cluster nodes. If the Swarm cluster is re-deployed, the server configuration
will need to be updated.

The role requires Docker Engine 18.02.0+. This includes the client running on the localhost.
