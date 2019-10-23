# InSpec test for recipe dnf-automatic::default

# The InSpec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/
describe package 'dnf-automatic' do
  it { should be_installed }
end

describe ini '/etc/dnf/automatic.conf' do
  its('commands.upgrade_type') { should cmp 'default' }
  its('commands.random_sleep') { should cmp 0 }
  its('commands.download_updates') { should cmp 'yes' }
  its('commands.apply_updates') { should cmp 'yes' }
  its('emitters.emit_via') { should cmp 'stdio' }
  its('email.email_from') { should cmp 'root@example.com' }
  its('email.email_to') { should cmp 'root' }
  its('email.email_host') { should cmp 'localhost' }
  its('command_email.email_from') { should cmp 'root@example.com' }
  its('command_email.email_to') { should cmp 'root' }
  its('base.debuglevel') { should cmp 1 }
end

describe service 'dnf-automatic.timer' do
  it { should be_enabled }
  it { should be_running }
end
