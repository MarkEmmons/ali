# Foundation

Inventory: A list of hosts

```Bash
# The default inventory file resides in /etc/ansible/hosts
ansible --list-hosts all

# We can specify a local file with the -i command
ansible -i ./ansible/dev --list-hosts all
```

```ini
# dev

[loadbalancer]
lb01

[webserver]
app01
app02

[database]
db01

[control]
# ansible_connection=local indicates we do not need to ssh into the control machine ansible is being run from
control ansible_connection=local
```

## Tasks

```Bash
# Calling the 'ping' module
ansible -m ping all


# Some modules, like the command module, take arguments
ansible -m command -a "hostname" all
```

## Plays and Playbooks

Create a playbook yaml file:

```YAML
# playbooks/hostname.yml
---
  - hosts: all
    tasks:
      - command: hostname
```

Run the book:

```Bash
ansible-playbook playbooks/hostname.yml
```

# Playbooks

Use the 'become' tag to run with elevated privileges.

__Handlers__ can be used along ith the __notify__ tag to run tasks when others complete.

### Modules

* pacman
* service
* copy