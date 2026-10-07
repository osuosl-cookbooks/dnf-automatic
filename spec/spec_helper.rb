require 'chefspec'
require 'chefspec/berkshelf'

Dir['libraries/*.rb'].each { |f| require File.expand_path(f) }

ALMA_8 = {
  platform: 'almalinux',
  version: '8',
}.freeze

ALMA_9 = {
  platform: 'almalinux',
  version: '9',
}.freeze

ALMA_10 = {
  platform: 'almalinux',
  version: '10',
}.freeze

ALL_PLATFORMS = [
  ALMA_8,
  ALMA_9,
  ALMA_10,
].freeze

RSpec.configure do |config|
  config.log_level = :warn
end

# ChefSpec runs actions in the root context, so what the delayed dnf_automatic_apply declares is
# never executed there; run it as the action's own runner would on a node.
def converge_delayed(chef_run)
  late = chef_run.resource_collection.all_resources.reject(&:executed_by_runner)
  late.each { |r| chef_run.run_context.runner.run_all_actions(r) }
  chef_run
end
