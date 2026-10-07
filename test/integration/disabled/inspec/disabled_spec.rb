describe file '/etc/dnf/automatic.conf' do
  it { should exist }
end

%w(dnf-automatic.timer dnf-automatic-download.timer dnf-automatic-install.timer dnf-automatic-notifyonly.timer).each do |timer|
  describe service timer do
    it { should_not be_enabled }
    it { should_not be_running }
  end
end
