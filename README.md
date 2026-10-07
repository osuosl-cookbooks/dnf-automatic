# dnf-automatic Cookbook

Manages [dnf-automatic](https://dnf.readthedocs.io/en/latest/automatic.html): the package, `/etc/dnf/automatic.conf`
and the `dnf-automatic.timer` schedule. It has no recipes or attributes; everything is done through two resources.

- [`dnf_automatic`](documentation/dnf_automatic.md) declares the host's baseline once. `base::packages` does this
  for every OSL EL host.
- [`dnf_automatic_policy`](documentation/dnf_automatic_policy.md) lets any other cookbook adjust that baseline (stop
  applying updates, exclude packages, reboot, security-only, error mail) without knowing about the others. Policies
  are merged with "most conservative wins" rules, in any declaration order.

```ruby
# base::packages
dnf_automatic 'default' do
  emit_via %w(email)
  email_from 'root@example.org'
  email_to %w(dnf-automatic@example.org)
  on_calendar '*-*-* 10:10 US/Pacific'
  randomized_delay '15m'
end

# a database cookbook
dnf_automatic_policy 'osl-foo' do
  exclude %w(mariadb*)
  reboot 'when-needed'
end
```

The resulting configuration is rendered once, at the end of the Chef run.

## Requirements

### Platforms

- AlmaLinux 8, 9 and 10

Some options are only honoured by newer dnf-automatic releases; see the
[release support table](documentation/dnf_automatic.md#release-support).

### Chef

- Chef 18+

### Cookbooks

- osl-resources

## Upgrading from 2.x

The `dnf-automatic::default` recipe and the `node['dnf-automatic']` attributes are gone. Replace
`include_recipe 'dnf-automatic'` and any attribute overrides with a `dnf_automatic` declaration, and use
`dnf_automatic_policy` from every other cookbook.

## Testing

Kitchen suites: `default` (base-like baseline), `policy` (policies around and inside other resources, EL9+) and
`disabled` (a policy turning the timer off). Each one runs a recipe from `test/cookbooks/dnf-automatic-test`.

## License and Authors

- Author:: Oregon State University <chef@osuosl.org>

```text
Copyright:: 2019-2026, Oregon State University

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
