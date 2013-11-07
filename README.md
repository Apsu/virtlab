Virtlab
===

Welcome to my little virt lab!

This is a simple Ansible orchestrator to kick a small cluster of Rackspace Cloud Servers. It will also provision the cluster as an HA Rackspace Private Cloud using the RPC Chef Cookbooks.

Requirements
---

A Rackspace Cloud account is required, as well as the pyrax library installed locally for Ansible's rax module to use. The upstream rax module doesn't currently support Rackspace Cloud Networks, which this project makes use of, so a minimally patched library is included.


Credentials
---

The provision-hosts role expects a rax_creds file to exist in the base directory with the following contents:

    [rackspace_cloud]
    username = someuser
    api_key = somekey

Workflow Playbooks
---

Currently there are two main playbooks combining various functional playbooks for common workflows:

* cluster.yml is the primary playbook for kicking an entire cluster, end to end. The included provision.yml will delete the hosts every time, so an easy way to rerun this is by passing --skip-tags delete-hosts to ansible-playbook. It then runs configure.yml and chef.yml to fully configure the cluster hosts and Chef it up.
* reconfigure.yml is designed for reconfiguring a cluster without rekicking the hosts. It will clean all of the Chef cruft and Openstack packages on the cluster in a way that lets you cleanly start the chef.yml again. This is handy for if Chef failed to configure the cluster completely, mysql is unhappy and your life is hard. Unlike cluster.yml, you'll want to pass --skip-tags delete-hosts every time here.

(TODO: Split delete/ensure into separate roles so these are a little more sane and flexible.)

Functional Playbooks
---

The functional playbooks are provision.yml, configure.yml, clean.yml and chef.yml. Each of the included plays are tagged by function and apply their tags to the roles they include for useful filtering.

Roles
---

There are several roles tailored to composable sets of functionality. Tasks in each role are also individually tagged for more granular filtering.



Provisioning
---

The static inventory provided (inventory/hosts) specifies the hostnames and groups but not their IP addresses, and must discover them. This is currently implemented in the provision-hosts role by first deleting any existing hosts (tag: delete-hosts), then building new ones with the inventory hostnames and registering the public IPv4 addresses for subsequent SSH access (tag: ensure-hosts). It is not necessary to delete hosts every time, as the building process is idempotent, discovering host information if they exist. Either way, ensure-hosts tags must always be run before any other playbooks.
