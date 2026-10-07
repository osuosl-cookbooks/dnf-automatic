provides :dnf_automatic
unified_mode true

default_action :configure

property :apply_updates, [true, false], default: true
property :base_options, Hash, default: { 'debuglevel' => 1 }
property :command_email_from, String, default: 'root@example.com'
property :command_email_to, Array, default: %w(root)
property :download_updates, [true, false], default: true
property :email_from, String, default: 'root@example.com'
property :email_host, String, default: 'localhost'
property :email_port, Integer, default: 25
property :email_tls, String, equal_to: %w(no yes starttls), default: 'no'
property :email_to, Array, default: %w(root)
property :emit_via, Array, default: %w(stdio), callbacks: {
  'must only contain stdio, email, motd, command or command_email' => ->(v) { (v - %w(stdio email motd command command_email)).empty? },
}
property :enabled, [true, false], default: true
property :exclude, Array, default: []
property :header, [true, false], default: true
property :network_online_timeout, Integer, default: 60
property :on_calendar, String
property :random_sleep, Integer, default: 0
property :randomized_delay, String
property :reboot, String, equal_to: %w(never when-changed when-needed), default: 'never'
property :reboot_command, String
property :send_error_messages, [true, false], default: false
property :system_name, String
property :upgrade_type, String, equal_to: %w(default security), default: 'default'

action :configure do
  state = dnf_automatic_state
  if state[:baseline] && state[:baseline][:name] != new_resource.name
    raise "dnf_automatic[#{new_resource.name}]: only one baseline is allowed, " \
          "dnf_automatic[#{state[:baseline][:name]}] is already declared"
  end

  package 'dnf-automatic'

  state[:baseline] = {
    name: new_resource.name,
    config: new_resource.class.properties(false).keys.to_h { |p| [p, new_resource.send(p)] },
  }

  dnf_automatic_schedule_apply
end
