# dnf-automatic Cookbook

The dnf-automatic cookbook takes over management of the ``dnf-automatic`` package which replaced ``yum-cron``. This
provides an automatic way to upgrade any dnf base operating system.

## Requirements

### Platforms

- CentOS >= 8
- AlmaLinux >= 8

### Chef

- Chef 16+

### Cookbooks

- none

## Attributes

The attributes build the ``/etc/dnf/automatic.conf`` configuration file using the following format:

```ruby
default['dnf-automatic']['conf']['section']['key'] = 'value'
```

Will generate the following in the config file:
```text
[section]
key = value
```

The default attributes match the current upstream defaults as installed on CentOS 8 with the exception of enabling
``apply_updates``. Please consult ``man dnf.automatic`` for more available configuration options.


```ruby
default['dnf-automatic']['conf']['commands']['upgrade_type'] = 'default'
default['dnf-automatic']['conf']['commands']['random_sleep'] = 0
default['dnf-automatic']['conf']['commands']['download_updates'] = 'yes'
default['dnf-automatic']['conf']['commands']['apply_updates'] = 'yes'
default['dnf-automatic']['conf']['emitters']['emit_via'] = 'stdio'
default['dnf-automatic']['conf']['email']['email_from'] = 'root@example.com'
default['dnf-automatic']['conf']['email']['email_to'] = 'root'
default['dnf-automatic']['conf']['email']['email_host'] = 'localhost'
default['dnf-automatic']['conf']['command_email']['email_from'] = 'root@example.com'
default['dnf-automatic']['conf']['command_email']['email_to'] = 'root'
default['dnf-automatic']['conf']['base']['debuglevel'] = 1
```

## Recipes

# Contributing

1. Fork the repository on Github
2. Create a named feature branch (like `username/add_component_x`)
3. Write tests for your change
4. Write your change
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

# License and Authors

- Author:: Oregon State University <chef@osuosl.org>

```text
Copyright:: 2019, Oregon State University

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
