#
# Cookbook Name:: aws-vpc-nat-instance
# Recipe:: monitoring
#
# Based on work by Yuki Takei (yuki@weseek.co.jp) https://github.com/weseek/chef-vpcnat
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

chef_gem 'aws-sdk' do
  version '2.0.32'
end

package 'jq'

# call library helper function
::Chef::Recipe.send(:include, AwsVpcNatInstance::Helper)

zone_conf = node['aws-vpc-nat-instance']['az'][instance_availability_zone]
zone_conf['opposite_primary_nat_id'] = get_opposite_primary_nat_id(zone_conf[:opposite_zone])
zone_conf['opposite_rtb'] = get_opposite_rtb_id(zone_conf[:opposite_zone])

# bag_item = data_bag_item_safely('sns', 'alert')

directory node['aws-vpc-nat-instance']['install_dir'] do
  owner node['aws-vpc-nat-instance']['user']
  group node['aws-vpc-nat-instance']['group']
  mode '755'
  action :create
end

template "#{node['aws-vpc-nat-instance']['install_dir']}/nat_monitor.sh" do
  source 'nat_monitor.sh.erb'
  owner node['aws-vpc-nat-instance']['user']
  group node['aws-vpc-nat-instance']['group']
  mode '755'
  variables({
                :enabled => zone_conf[:enabled],
                :region => region,
                :instance_id => instance_id,
                :opposite_rtb_id => zone_conf[:opposite_rtb],
                :opposite_primary_nat_id => zone_conf[:opposite_primary_nat_id],
                :internet_access_test_ip => zone_conf[:internet_access_test_ip],
                # :sns_arn => bag_item['dest_arn'],
                # :sns_region => bag_item['region'],
                :sns_enabled => node['aws-vpc-nat-instance'][:sns_enabled],
                :jq => node['aws-vpc-nat-instance'][:jq],
                :aws => node['aws-vpc-nat-instance'][:awscli]
            })
end

# TODO run script as a service
=begin
cron_d 'nat_monitoring' do
  user node['aws-vpc-nat-instance'][:user]
  minute '*'
  hour '*'
  day '*'
  month '*'
  weekday '*'

  # run every 30s
  command "(#{node['aws-vpc-nat-instance'][:install_dir]}/nat_monitoring.sh & sleep 30; #{node['aws-vpc-nat-instance'][:install_dir]}/nat_monitoring.sh) >/dev/null 2>&1"
end=end
