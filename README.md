[![Build Status](http://jenkins.propter.net:8080/buildStatus/icon?job=ansible)](http://jenkins.propter.net:8080/job/ansible/)

Description
===

Welcome to my little virt lab!

This is a simple Ansible orchestrator to kick a small cluster of Rackspace Cloud Servers. It will also provision the cluster as an HA Rackspace Private Cloud using the RPC Chef Cookbooks. This is primarily designed to be run from Jenkins, and plumbing is provided to dynamically generate host/network metadata from environment variables passed to the build scripts.

Requirements
---

A Rackspace Cloud account is required, as well as the `pyrax` library installed locally for Ansible's `rax` module to use.

Credentials
---

The ensure-hosts role expects a `rax_creds` file to exist in the base directory with the following contents:

    [rackspace_cloud]
    username = someuser
    api_key = somekey

Inventory (Hosts)
---

The inventory is currently configured (via `ansible.cfg`) as a directory in the project root, `./inventory`, and contains `group_vars` and the `hosts` file. The included `hosts` file is very minimal since `jenkins.yml` generates hosts dynamically, but you can specify a static inventory if you like, and not use `jenkins.yml`. Either way, the structure of hosts and groups is as follows:

* Local -- Group for local_action targeting
  * Just contains "localhost" at present
* Chef -- Group for the single Chef server
* Infra -- Group for the pair of HA controller nodes
  * The order of hosts here will dictate controller1/controller2 mapping
* Compute -- Group for compute nodes

These groups are then collected and divided into two other useful groups for targeting by various roles:

* Hosts -- This contains all hosts for site-wide tasks
* Cluster -- This contains everything but the chef host, for chef tasks

`group_vars` set a few bits of miscellaneous info, though these are particularly important:

* group_vars/chef.yml -- Configuration for chef server and clients
* group_vars/all.yml -- Configuration for images, networks, various ansible bits

Workflow Playbooks
---

Currently there are two main playbooks combining various functional playbooks for common workflows:

* `build.yml` is the primary playbook for kicking an entire cluster, end to end. The included `ensure.yml` will ensure the hosts exist, creating them if needed. It then runs `configure.yml` and `chef.yml` to fully configure the cluster hosts and chef it up.
* `rebuild.yml` is the same as `build.yml` but first runs `delete.yml` to delete the hosts if they already exist.
* `reconfigure.yml` is designed for reconfiguring a cluster without rekicking the hosts. It will clean all of the chef cruft and Openstack packages on the cluster in a way that lets you cleanly start the `chef.yml` again. This is handy for if chef failed to configure the cluster completely, mysql is unhappy and your life is hard.

Functional Playbooks
---

The functional playbooks are `jenkins.yml`, `ensure.yml`, `delete.yml`, `configure.yml`, `clean.yml` and `chef.yml`. Each of the included plays are tagged by function and apply their tags to the roles they include for useful filtering.

As mentioned previously, `jenkins.yml` provides dynamic hostname/network generation for consumption by subsequent playbooks.

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
* delete-hosts -- Deletes host servers
* ensure-hosts -- Creates host servers and learns how to talk to them for other roles
* reboot-cluster -- Reboots the cluster nodes and waits for them to be responsive again

Jenkins
---

The two scripts designed to be run from Jenkins are `build.sh` and `delete.sh`. They're fairly simple wrappers around the `build.yml` and `delete.yml` playbooks, respectively. They also dumbly assume this repo is cloned in /opt/virtlab and ansible is in a virtualenv named `.venv`. You're welcome.

Networking
---

Custom cloud networks are dealt with in the same way (and in the same playbooks) as hosts, created or deleted as required, and associated with hosts as required. Refer to the `jenkins.yml` playbook and `group_vars/all.yml` for details on network specification format and default values.

Provisioning
---

Whether provided statically or generated dynamically, we will know hostnames and groups but not their IP addresses, and must discover them. This is currently implemented in the `ensure-hosts` role by building new ones (if they don't exist) with the inventory hostnames and registering the public IPv4 addresses for subsequent SSH access. You can also delete the hosts with the `delete-hosts` role; the `rebuild.yml` playbook does this before building new ones. It is not necessary to delete hosts every time as the building process is idempotent, discovering host information if they exist. Either way, `ensure-*` tags must always be run before any other playbooks.

Errata
===

Some tasks -- mostly chef tooling and chef-related -- are a little terrible to figure out their current state and decide if running them caused a change or not. Please try to forgive some of the travesties you'll encounter involving abuse of failed_when, changed_when and friends.
