# Internal: queued once at the end of the run by dnf_automatic and dnf_automatic_policy.
provides :dnf_automatic_apply
unified_mode true

default_action :apply

action :apply do
  state = dnf_automatic_state
  unless state[:baseline]
    Chef::Log.info("dnf_automatic_policy #{state[:policies].keys.join(', ')} ignored: no dnf_automatic baseline on this node")
    return
  end

  unreached = dnf_automatic_unreached(run_context.root_run_context.resource_collection.all_resources)
  unless unreached.empty?
    Chef::Log.warn("dnf-automatic: run failed before #{unreached.first}; keeping the existing configuration")
    return
  end

  el_major = node['platform_version'].to_i
  baseline = state[:baseline][:config]
  config = dnf_automatic_merge(baseline, state[:policies])

  unsupported = dnf_automatic_unsupported(config, el_major)
  unless unsupported.empty?
    detail = unsupported.map do |option|
      sources = state[:policies].select { |_, p| p.key?(option) }.keys.map { |n| "dnf_automatic_policy[#{n}]" }
      sources << "dnf_automatic[#{state[:baseline][:name]}]" if sources.empty?
      "#{option} = #{config[option].inspect} (#{sources.join(', ')})"
    end
    raise "dnf-automatic on EL#{el_major} ignores: #{detail.join('; ')}"
  end

  template '/etc/dnf/automatic.conf' do
    source 'automatic.conf.erb'
    cookbook 'dnf-automatic'
    variables(
      header: config[:header],
      sections: dnf_automatic_sections(config, el_major)
    )
  end

  dropin = dnf_automatic_timer_dropin(config[:on_calendar], config[:randomized_delay])

  osl_systemd_unit_drop_in 'dnf-automatic' do
    override_name 'osuosl'
    unit_name 'dnf-automatic.timer'
    content dropin if dropin
    action dropin ? :create : :delete
  end

  service 'dnf-automatic.timer' do
    action config[:enabled] ? %i(enable start) : %i(stop disable)
  end

  # Their units pass flags that override automatic.conf, and dnf5 drops them.
  DNF_AUTOMATIC_MODE_TIMERS.each do |timer|
    service timer do
      action %i(stop disable)
    end
  end
end
