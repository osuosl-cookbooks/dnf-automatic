provides :dnf_automatic_policy
unified_mode true

default_action :add

# Unset properties carry no opinion; see documentation/dnf_automatic_policy.md for the merge rules.
property :apply_updates, [true, false]
property :download_updates, [true, false]
property :enabled, [true, false]
property :exclude, Array, default: []
property :reboot, String, equal_to: %w(never when-changed when-needed)
property :send_error_messages, [true, false]
property :upgrade_type, String, equal_to: %w(default security)

action :add do
  dnf_automatic_state[:policies][new_resource.name] =
    new_resource.class.properties(false).keys.to_h { |p| [p, new_resource.send(p)] }.compact

  dnf_automatic_schedule_apply
end
