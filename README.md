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

Inventory (Hosts)
---

The inventory is currently configured (via ansible.cfg) as a directory in the project root, ./inventory, and contains host_vars, group_vars and the hosts file. The hosts file is a simple collection of hostnames and groups they're in, with the following main structure:

* Local -- Group for local_action targeting
  * Just contains "localhost" at present
* Chef -- Group for the single Chef server
* Infra -- Group for the pair of HA controller nodes
  * The order of hosts here will dictate controller1/controller2 mapping
* Compute -- Group for compute nodes

These groups are then collected and divided into two other useful groups for targeting by various roles:

* Hosts -- This contains all hosts for site-wide tasks
* Cluster -- This contains everything but the chef host, for chef tasks

host_vars/group_vars set a few bits of miscellaneous info, though these are particularly important:

* group_vars/chef.yml -- Configuration for chef server and clients
* group_vars/hosts.yml -- Configuration for rax module to kick servers
* host_vars/$host.yml -- Network interface reconfiguration data per host

Workflow Playbooks
---

Currently there are two main playbooks combining various functional playbooks for common workflows:

* cluster.yml is the primary playbook for kicking an entire cluster, end to end. The included provision.yml will delete the hosts every time, so an easy way to rerun this is by passing --skip-tags delete-hosts to ansible-playbook. It then runs configure.yml and chef.yml to fully configure the cluster hosts and chef it up.
* reconfigure.yml is designed for reconfiguring a cluster without rekicking the hosts. It will clean all of the chef cruft and Openstack packages on the cluster in a way that lets you cleanly start the chef.yml again. This is handy for if chef failed to configure the cluster completely, mysql is unhappy and your life is hard. Unlike cluster.yml, you'll want to pass --skip-tags delete-hosts every time here.

Functional Playbooks
---

The functional playbooks are provision.yml, configure.yml, clean.yml and chef.yml. Each of the included plays are tagged by function and apply their tags to the roles they include for useful filtering.

Roles
---

There are several roles tailored to composable sets of functionality. Tasks in each role are also individually tagged for more granular filtering. These include:

* chef-client -- Runs chef-client on cluster nodes
* chef-roles -- Configures cluster node roles for chef mapping by chef-centric groups
* chef-setup -- Installs chef-server and does other appropriate needfuls
* clean-chef-nodes -- Wipes cluster nodes from chef-server's memory
* clean-chef-server -- Removes chef-server packages and files, kills processes on chef node
* clean-chef-cluser -- Removes chef packages and files, kills processes on cluster nodes
* configure-hosts -- Basic post-install groundwork, configures networking and tests it
* provision-hosts -- Deletes/Builds servers and learns how to talk to them for other roles
* reboot-cluster -- Reboots the cluster nodes and waits for them to be responsive again

Provisioning
---

The static inventory provided specifies the hostnames and groups but not their IP addresses, and must discover them. This is currently implemented in the provision-hosts role by first deleting any existing hosts (tag: delete-hosts), then building new ones with the inventory hostnames and registering the public IPv4 addresses for subsequent SSH access (tag: ensure-hosts). It is not necessary to delete hosts every time, as the building process is idempotent, discovering host information if they exist. Either way, ensure-hosts tags must always be run before any other playbooks.

Errata
===

Some tasks -- mostly chef tooling and chef-related -- are a little terrible to figure out their current state and decide if running them caused a change or not. Please try to forgive some of the travesties you'll encounter involving abuse of failed_when, changed_when and friends.
