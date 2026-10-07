# dnf_automatic_policy

Adjusts the host's [`dnf_automatic`](dnf_automatic.md) baseline from any cookbook. Each cookbook declares its own
policy, named after itself or the reason, and states only the settings it cares about. Policies:

- can be declared before or after the baseline, from a recipe or from inside another custom resource's action;
- honour `only_if` and `not_if`: a skipped policy has no effect;
- are merged with each other and with the baseline once, at the end of the run.

A policy on a node with no `dnf_automatic` baseline does nothing (it logs one info line): if nothing manages
dnf-automatic there, there is nothing to adjust. This keeps consumer kitchen suites that leave out `base::packages`
working, and a policy never installs dnf-automatic by itself.

## Merge rules

A setting no policy mentions keeps the baseline's value. A setting one policy mentions takes that policy's value.
When several policies set the same field, the more conservative value wins:

| Setting | Winning value |
|---|---|
| `enabled` | `false` |
| `apply_updates` | `false` |
| `download_updates` | `false`; this also turns `apply_updates` off, since dnf-automatic always downloads what it applies |
| `upgrade_type` | `security` |
| `reboot` | `never`, then `when-needed`, then `when-changed` |
| `send_error_messages` | `true` |
| `exclude` | the baseline's list plus every policy's, in policy-name order |

The [release support](dnf_automatic.md#release-support) rules apply to the merged result: a policy asking for
`reboot 'when-needed'` on EL8 fails the run and is named in the error.

## Actions

| Action | Description |
|---|---|
| `:add` | Default. Records the policy for the end-of-run merge. |

## Properties

All default to "no opinion".

| Property | Type | Description |
|---|---|---|
| `enabled` | true, false | `false` stops and disables `dnf-automatic.timer`. |
| `apply_updates` | true, false | `false` keeps downloading and notifying but never installs. |
| `download_updates` | true, false | `false` makes the host notify only. |
| `upgrade_type` | `default`, `security` | `security` limits updates to security advisories. |
| `reboot` | `never`, `when-changed`, `when-needed` | Reboot after applying updates. EL9+. |
| `send_error_messages` | true, false | Emit failed runs as well. EL9+. |
| `exclude` | Array | Package globs to hold back from automatic updates. |

## Examples

```ruby
# Hold the database packages back on a database host
dnf_automatic_policy 'osl-foo' do
  exclude %w(mariadb* galera*)
end
```

```ruby
# Turn automatic updates off while an upgrade is in progress
dnf_automatic_policy 'osl-foo-upgrade' do
  enabled false
  not_if { ::File.exist?('/root/upgrade-done') }
end
```

```ruby
# From inside a custom resource's action
action :create do
  dnf_automatic_policy "osl-foo-#{new_resource.name}" do
    upgrade_type 'security'
  end
end
```
