# Declares a policy from inside an action, as a service cookbook's resource would.
provides :dnf_automatic_test_nested
unified_mode true

default_action :create

property :package_glob, String, name_property: true

action :create do
  dnf_automatic_policy 'nested' do
    exclude [new_resource.package_glob]
  end
end
