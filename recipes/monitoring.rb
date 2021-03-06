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

include_recipe 'awscli::default'

package 'jq'

# call library helper function
::Chef::Recipe.send(:include, AwsVpcNatInstance::Helper)

zone = get_instance_availability_zone
region = get_region
local_nat_id = get_instance_id
local_nat_ip = get_instance_private_ip
opposite_zone = node['aws-vpc-nat-instance']['monitoring']['az'][zone]['opposite_zone']
node.default['aws-vpc-nat-instance']['monitoring']['az'][zone]['opposite_nat_id'] = get_nat_id(opposite_zone)
node.default['aws-vpc-nat-instance']['monitoring']['az'][zone]['local_rtb_id'] = get_rtb_id(zone)
node.default['aws-vpc-nat-instance']['monitoring']['az'][zone]['opposite_rtb_id'] = get_rtb_id(opposite_zone)
zone_conf = node['aws-vpc-nat-instance']['monitoring']['az'][zone]

# Add user for nat_monitoring script to run
group node['aws-vpc-nat-instance']['monitoring']['user'] do
  action :create
end

user node['aws-vpc-nat-instance']['monitoring']['user'] do
  comment 'NAT monitoring user'
  home node['aws-vpc-nat-instance']['monitoring']['install_dir']
  shell '/bin/false'
  system true
  gid node['aws-vpc-nat-instance']['monitoring']['user']
end

directory node['aws-vpc-nat-instance']['monitoring']['install_dir'] do
  owner node['aws-vpc-nat-instance']['monitoring']['user']
  group node['aws-vpc-nat-instance']['monitoring']['user']
  mode '755'
  action :create
end

template 'nat_monitor_sh' do
  path "#{node['aws-vpc-nat-instance']['monitoring']['install_dir']}/nat_monitor.sh"
  source 'nat_monitor.sh.erb'
  owner node['aws-vpc-nat-instance']['monitoring']['user']
  group node['aws-vpc-nat-instance']['monitoring']['user']
  mode '755'
  variables({
                :region => region,
                :local_nat_id => local_nat_id,
                :local_nat_ip => local_nat_ip,
                :local_rtb_id => zone_conf[:local_rtb_id],
                :opposite_rtb_id => zone_conf[:opposite_rtb_id],
                :opposite_nat_id => zone_conf[:opposite_nat_id],
                :internet_access_test_ip => node['aws-vpc-nat-instance']['monitoring']['internet_access_test_ip'],
                :number_of_pings => node['aws-vpc-nat-instance']['monitoring']['number_of_pings'],
                :ping_timeout => node['aws-vpc-nat-instance']['monitoring']['ping_timeout'],
                :wait_between_checks => node['aws-vpc-nat-instance']['monitoring']['wait_between_checks'],
                :sns_enabled => node['aws-vpc-nat-instance']['monitoring'][:sns_enabled],
                :sns_arn => node['aws-vpc-nat-instance']['monitoring']['sns_arn'],
                :jq => node['aws-vpc-nat-instance'][:jq],
                :aws => node['aws-vpc-nat-instance'][:awscli]
            })
end

supervisor_service 'nat-monitor' do
  command "#{node['aws-vpc-nat-instance']['monitoring']['install_dir']}/nat_monitor.sh"
  directory node['aws-vpc-nat-instance']['monitoring']['install_dir']
  user node['aws-vpc-nat-instance']['monitoring']['user']
  action :enable
  autostart true
  subscribes :restart, 'template[nat_monitor_sh]', :delayed
end

