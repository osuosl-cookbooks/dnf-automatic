#
# Cookbook:: dnf-automatic-test
# Recipe:: policy
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

# Declared before the baseline on purpose.
dnf_automatic_policy 'early' do
  exclude %w(mariadb*)
  reboot 'when-needed'
end

include_recipe 'dnf-automatic-test::default'

dnf_automatic_policy 'late' do
  apply_updates false
  reboot 'when-changed'
  send_error_messages true
  upgrade_type 'security'
end

dnf_automatic_policy 'guarded' do
  enabled false
  only_if { false }
end

dnf_automatic_test_nested 'postgresql*'
