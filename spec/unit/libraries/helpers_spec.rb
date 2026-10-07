require_relative '../../spec_helper'

describe DnfAutomatic::Cookbook::Helpers do
  subject { Object.new.extend(described_class) }

  let(:baseline) do
    {
      apply_updates: true,
      base_options: { 'debuglevel' => 1 },
      command_email_from: 'root@example.org',
      command_email_to: %w(root),
      download_updates: true,
      email_from: 'root@example.org',
      email_host: 'localhost',
      email_port: 25,
      email_tls: 'no',
      email_to: %w(dnf-automatic@example.org),
      emit_via: %w(email),
      enabled: true,
      exclude: %w(kernel*),
      network_online_timeout: 60,
      random_sleep: 0,
      reboot: 'never',
      reboot_command: nil,
      send_error_messages: false,
      system_name: nil,
      upgrade_type: 'default',
    }
  end

  describe '#dnf_automatic_supported?' do
    it { expect(subject.dnf_automatic_supported?(:apply_updates, 8)).to be true }
    it { expect(subject.dnf_automatic_supported?(:reboot, 8)).to be false }
    it { expect(subject.dnf_automatic_supported?('reboot', 9)).to be true }
    it { expect(subject.dnf_automatic_supported?(:email_tls, 9)).to be false }
    it { expect(subject.dnf_automatic_supported?(:email_tls, 10)).to be true }
  end

  describe '#dnf_automatic_unsupported' do
    it { expect(subject.dnf_automatic_unsupported(baseline, 8)).to eq [] }
    it { expect(subject.dnf_automatic_unsupported(baseline.merge(reboot: 'when-needed', email_port: 587), 8)).to eq %i(email_port reboot) }
    it { expect(subject.dnf_automatic_unsupported(baseline.merge(email_tls: 'starttls'), 9)).to eq %i(email_tls) }
    it { expect(subject.dnf_automatic_unsupported(baseline.merge(email_tls: 'starttls', reboot: 'when-needed'), 10)).to eq [] }
  end

  describe '#dnf_automatic_merge' do
    it 'keeps the baseline without policies' do
      expect(subject.dnf_automatic_merge(baseline, {})).to eq baseline
    end

    it 'lets a single policy override the baseline' do
      merged = subject.dnf_automatic_merge(baseline, 'a' => { reboot: 'when-changed', upgrade_type: 'security' })
      expect(merged).to include(reboot: 'when-changed', upgrade_type: 'security')
    end

    it 'picks the most conservative value across policies' do
      merged = subject.dnf_automatic_merge(
        baseline,
        'a' => { enabled: true, apply_updates: true, reboot: 'when-changed', upgrade_type: 'default', send_error_messages: false },
        'b' => { enabled: false, apply_updates: false, reboot: 'when-needed', upgrade_type: 'security', send_error_messages: true }
      )
      expect(merged).to include(
        enabled: false, apply_updates: false, reboot: 'when-needed', upgrade_type: 'security', send_error_messages: true
      )
    end

    it 'prefers never over any other reboot setting' do
      merged = subject.dnf_automatic_merge(baseline, 'a' => { reboot: 'never' }, 'b' => { reboot: 'when-needed' })
      expect(merged[:reboot]).to eq 'never'
    end

    it 'unions excludes in policy name order' do
      merged = subject.dnf_automatic_merge(baseline, 'z' => { exclude: %w(foo*) }, 'a' => { exclude: %w(bar* kernel*) })
      expect(merged[:exclude]).to eq %w(kernel* bar* foo*)
    end

    it 'stops applying when a policy turns off downloads' do
      merged = subject.dnf_automatic_merge(baseline, 'a' => { download_updates: false })
      expect(merged).to include(download_updates: false, apply_updates: false)
    end

    it 'does not modify the baseline' do
      subject.dnf_automatic_merge(baseline, 'a' => { exclude: %w(foo*), reboot: 'when-needed' })
      expect(baseline).to include(exclude: %w(kernel*), reboot: 'never')
    end
  end

  describe '#dnf_automatic_sections' do
    let(:config) { baseline.merge(system_name: 'web1', reboot: 'when-needed', reboot_command: 'reboot') }

    it 'leaves out what EL8 ignores' do
      sections = subject.dnf_automatic_sections(config, 8)
      expect(sections['commands']).to_not include(:reboot, :reboot_command)
      expect(sections['emitters']).to_not include(:send_error_messages)
      expect(sections['email']).to_not include(:email_port, :email_tls)
    end

    it 'renders EL9 options but not email_tls' do
      sections = subject.dnf_automatic_sections(config, 9)
      expect(sections['commands']).to include(reboot: 'when-needed', reboot_command: 'reboot')
      expect(sections['emitters']).to include(send_error_messages: 'no', system_name: 'web1')
      expect(sections['email']).to include(email_port: '25')
      expect(sections['email']).to_not include(:email_tls)
    end

    it 'renders every option on EL10' do
      expect(subject.dnf_automatic_sections(config, 10)['email']).to include(email_tls: 'no')
    end

    it 'formats values and passes [base] options through' do
      sections = subject.dnf_automatic_sections(config, 10)
      expect(sections['commands']).to include(apply_updates: 'yes', random_sleep: '0', upgrade_type: 'default')
      expect(sections['base']).to eq(debuglevel: '1', exclude: 'kernel*')
    end

    it 'omits unset values and an empty exclude' do
      sections = subject.dnf_automatic_sections(baseline.merge(exclude: []), 10)
      expect(sections['emitters']).to_not include(:system_name)
      expect(sections['commands']).to_not include(:reboot_command)
      expect(sections['base']).to_not include(:exclude)
    end
  end

  describe '#dnf_automatic_value' do
    it { expect(subject.dnf_automatic_value(true)).to eq 'yes' }
    it { expect(subject.dnf_automatic_value(false)).to eq 'no' }
    it { expect(subject.dnf_automatic_value(%w(a b))).to eq 'a b' }
    it { expect(subject.dnf_automatic_value(5)).to eq '5' }
  end

  describe '#dnf_automatic_unreached' do
    let(:ran) { double('ran', executed_by_runner: true, to_s: 'package[a]') }
    let(:skipped) { double('skipped', executed_by_runner: nil, to_s: 'dnf_automatic_policy[held]') }

    it { expect(subject.dnf_automatic_unreached([ran])).to eq [] }
    it { expect(subject.dnf_automatic_unreached([ran, skipped])).to eq %w(dnf_automatic_policy[held]) }
  end

  describe '#dnf_automatic_timer_dropin' do
    it { expect(subject.dnf_automatic_timer_dropin(nil, nil)).to be_nil }
    it do
      expect(subject.dnf_automatic_timer_dropin('*-*-* 10:10 US/Pacific', '15m')).to eq <<~EOF
        [Timer]
        OnCalendar=
        OnCalendar=*-*-* 10:10 US/Pacific
        RandomizedDelaySec=15m
      EOF
    end
    it { expect(subject.dnf_automatic_timer_dropin(nil, '5m')).to eq "[Timer]\nRandomizedDelaySec=5m\n" }
  end
end
