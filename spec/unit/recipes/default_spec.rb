require_relative '../../spec_helper'

describe 'dnf-automatic::default' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      case p
      when CENTOS_8
        it do
          expect(chef_run).to install_package('dnf-automatic')
        end
        it do
          expect(chef_run).to create_template('/etc/dnf/automatic.conf')
        end
        [
          /^upgrade_type = default$/,
          /^random_sleep = 0$/,
          /^download_updates = yes$/,
          /^apply_updates = yes$/,
          /^emit_via = stdio$/,
          /^email_from = root@example.com$/,
          /^email_to = root$/,
          /^email_host = localhost$/,
          /^debuglevel = 1$/,
        ].each do |line|
          it do
            expect(chef_run).to render_file('/etc/dnf/automatic.conf').with_content(line)
          end
        end
        it do
          expect(chef_run).to enable_service('dnf-automatic.timer')
          expect(chef_run).to start_service('dnf-automatic.timer')
        end
      when CENTOS_7
        it do
          expect(chef_run).to_not install_package('dnf-automatic')
        end
        it do
          expect(chef_run).to_not create_template('/etc/dnf/automatic.conf')
        end
        it do
          expect(chef_run).to_not enable_service('dnf-automatic.timer')
          expect(chef_run).to_not start_service('dnf-automatic.timer')
        end
      end
    end
  end
end
