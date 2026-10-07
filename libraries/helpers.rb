#
# Cookbook:: dnf-automatic
# Library:: helpers
#
# Copyright:: 2026, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
module DnfAutomatic
  module Cookbook
    module Helpers
      # First EL major whose dnf-automatic honours the option; older releases silently ignore it.
      DNF_AUTOMATIC_MIN_EL = {
        email_port: 9,
        email_tls: 10,
        reboot: 9,
        reboot_command: 9,
        send_error_messages: 9,
      }.freeze

      # Behaviour of a gated option when it is left alone.
      DNF_AUTOMATIC_GATED_DEFAULTS = {
        email_port: 25,
        email_tls: 'no',
        reboot: 'never',
        reboot_command: nil,
        send_error_messages: false,
      }.freeze

      DNF_AUTOMATIC_REBOOT_ORDER = %w(never when-needed when-changed).freeze

      DNF_AUTOMATIC_MODE_TIMERS = %w(
        dnf-automatic-download.timer
        dnf-automatic-install.timer
        dnf-automatic-notifyonly.timer
      ).freeze

      def dnf_automatic_supported?(option, el_major)
        el_major >= DNF_AUTOMATIC_MIN_EL.fetch(option.to_sym, 0)
      end

      # Gated options set to something other than their default on a release that ignores them.
      def dnf_automatic_unsupported(config, el_major)
        DNF_AUTOMATIC_GATED_DEFAULTS.select do |option, default|
          !dnf_automatic_supported?(option, el_major) && config[option] != default
        end.keys
      end

      # Policies override the baseline; among policies the most conservative value wins.
      def dnf_automatic_merge(baseline, policies)
        merged = baseline.dup
        set = ->(key) { policies.values.map { |p| p[key] }.compact }

        %i(enabled apply_updates download_updates).each do |key|
          merged[key] = set.call(key).all? unless set.call(key).empty?
        end
        merged[:upgrade_type] = set.call(:upgrade_type).include?('security') ? 'security' : 'default' unless set.call(:upgrade_type).empty?
        merged[:reboot] = set.call(:reboot).min_by { |r| DNF_AUTOMATIC_REBOOT_ORDER.index(r) } unless set.call(:reboot).empty?
        merged[:send_error_messages] = set.call(:send_error_messages).any? unless set.call(:send_error_messages).empty?
        merged[:exclude] = (baseline[:exclude] + policies.keys.sort.flat_map { |n| policies[n][:exclude] || [] }).uniq

        # dnf-automatic downloads whenever it applies, so a download-only opinion has to stop applying too.
        merged[:apply_updates] = false unless merged[:download_updates]
        merged
      end

      # Ordered sections for automatic.conf, leaving out whatever this release would ignore.
      def dnf_automatic_sections(config, el_major)
        sections = {
          'commands' => {
            upgrade_type: config[:upgrade_type],
            random_sleep: config[:random_sleep],
            network_online_timeout: config[:network_online_timeout],
            download_updates: config[:download_updates],
            apply_updates: config[:apply_updates],
            reboot: config[:reboot],
            reboot_command: config[:reboot_command],
          },
          'emitters' => {
            system_name: config[:system_name],
            emit_via: config[:emit_via],
            send_error_messages: config[:send_error_messages],
          },
          'email' => {
            email_from: config[:email_from],
            email_to: config[:email_to],
            email_host: config[:email_host],
            email_port: config[:email_port],
            email_tls: config[:email_tls],
          },
          'command_email' => {
            email_from: config[:command_email_from],
            email_to: config[:command_email_to],
          },
          'base' => config[:base_options].transform_keys(&:to_sym).merge(
            exclude: config[:exclude].empty? ? nil : config[:exclude]
          ),
        }

        sections.transform_values do |opts|
          opts.select { |k, v| !v.nil? && dnf_automatic_supported?(k, el_major) }
              .transform_values { |v| dnf_automatic_value(v) }
        end
      end

      def dnf_automatic_value(value)
        case value
        when true then 'yes'
        when false then 'no'
        when Array then value.join(' ')
        else value.to_s
        end
      end

      # Content for the dnf-automatic.timer drop-in, or nil to keep the packaged schedule.
      def dnf_automatic_timer_dropin(on_calendar, randomized_delay)
        return if on_calendar.nil? && randomized_delay.nil?

        lines = ['[Timer]']
        lines += ['OnCalendar=', "OnCalendar=#{on_calendar}"] if on_calendar
        lines << "RandomizedDelaySec=#{randomized_delay}" if randomized_delay
        lines.join("\n") + "\n"
      end

      # Chef runs delayed actions even when the converge failed; resources it never reached mean policies may be missing.
      def dnf_automatic_unreached(resources)
        resources.reject(&:executed_by_runner).map(&:to_s)
      end

      def dnf_automatic_state
        node.run_state['dnf_automatic'] ||= { baseline: nil, policies: {} }
      end

      # Queue the single end-of-run apply in the root context, so nested and late declarations count.
      def dnf_automatic_schedule_apply
        with_run_context :root do
          find_resource(:dnf_automatic_apply, 'default') do
            action :nothing
            delayed_action :apply
          end
        end
      end
    end
  end
end
Chef::DSL::Recipe.include ::DnfAutomatic::Cookbook::Helpers
Chef::Resource.include ::DnfAutomatic::Cookbook::Helpers
