describe ini '/etc/dnf/automatic.conf' do
  its('commands.upgrade_type') { should cmp 'security' }
  its('commands.download_updates') { should cmp 'yes' }
  its('commands.apply_updates') { should cmp 'no' }
  its('commands.reboot') { should cmp 'when-needed' }
  its('emitters.send_error_messages') { should cmp 'yes' }
  its('base.exclude') { should cmp 'mariadb* postgresql*' }
end

# The guarded policy never applied, so the timer stays on.
describe service 'dnf-automatic.timer' do
  it { should be_enabled }
  it { should be_running }
end
