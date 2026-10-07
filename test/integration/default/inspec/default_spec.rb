el = os.release.to_i

describe package 'dnf-automatic' do
  it { should be_installed }
end

describe ini '/etc/dnf/automatic.conf' do
  its('commands.upgrade_type') { should cmp 'default' }
  its('commands.random_sleep') { should cmp 0 }
  its('commands.network_online_timeout') { should cmp 60 }
  its('commands.download_updates') { should cmp 'yes' }
  its('commands.apply_updates') { should cmp 'yes' }
  its('emitters.emit_via') { should cmp 'email' }
  its('email.email_from') { should cmp 'root@example.org' }
  its('email.email_to') { should cmp 'dnf-automatic@example.org' }
  its('email.email_host') { should cmp 'localhost' }
  its('command_email.email_from') { should cmp 'root@example.org' }
  its('command_email.email_to') { should cmp 'root' }
  its('base.debuglevel') { should cmp 1 }
  its('base.exclude') { should be_nil }
  if el >= 9
    its('commands.reboot') { should cmp 'never' }
    its('emitters.send_error_messages') { should cmp 'no' }
    its('email.email_port') { should cmp 25 }
  else
    its('commands.reboot') { should be_nil }
    its('emitters.send_error_messages') { should be_nil }
  end
  its('email.email_tls') { should(el >= 10 ? cmp('no') : be_nil) }
end

describe service 'dnf-automatic.timer' do
  it { should be_enabled }
  it { should be_running }
end

describe command 'systemctl show dnf-automatic.timer' do
  its('stdout') { should match %r{OnCalendar=\*-\*-\* 10:10:00 US/Pacific} }
  its('stdout') { should match /RandomizedDelayUSec=15min/ }
end

%w(dnf-automatic-download.timer dnf-automatic-install.timer dnf-automatic-notifyonly.timer).each do |timer|
  describe service timer do
    it { should_not be_enabled }
    it { should_not be_running }
  end
end
