default['aws-vpc-nat-instance']['default_environment_name'] = 'prod'
default['aws-vpc-nat-instance']['ipmasq_src'] = '10.0.0.0/16'
default['aws-vpc-nat-instance']['interface'] = 'eth0'
default['aws-vpc-nat-instance']['access_key_id'] = nil
default['aws-vpc-nat-instance']['secret_access_key'] = nil
default['aws-vpc-nat-instance']['disable_source_dest_check'] = false
default['aws-vpc-nat-instance']['sns_enabled'] = false
default['aws-vpc-nat-instance']['install_dir'] = '/usr/local/bin'
default['aws-vpc-nat-instance']['user'] = 'root'
default['aws-vpc-nat-instance']['group'] = 'root'
default['aws-vpc-nat-instance']['internet_access_test_ip'] = '8.8.4.4'
default['aws-vpc-nat-instance']['number_of_pings'] = '3'
default['aws-vpc-nat-instance']['ping_timeout'] = '2s'
default['aws-vpc-nat-instance']['wait_between_checks'] = '10s'
default['aws-vpc-nat-instance']['monitoring_enabled'] = true
default['aws-vpc-nat-instance']['az'] = {}
default['aws-vpc-nat-instance']['az']['us-east-1b'] = {}
default['aws-vpc-nat-instance']['az']['us-east-1b']['opposite_zone'] = 'us-east-1c'
default['aws-vpc-nat-instance']['az']['us-east-1c'] = {}
default['aws-vpc-nat-instance']['az']['us-east-1c']['opposite_zone'] = 'us-east-1b'
default['aws-vpc-nat-instance']['az']['us-east-1d'] = {}
default['aws-vpc-nat-instance']['az']['us-east-1d']['opposite_zone'] = 'us-east-1e'
default['aws-vpc-nat-instance']['az']['us-east-1e'] = {}
default['aws-vpc-nat-instance']['az']['us-east-1e']['opposite_zone'] = 'us-east-1d'
default['aws-vpc-nat-instance']['jq'] = '/usr/bin/jq'

if platform?('amazon')
  # pre-installed
  default['aws-vpc-nat-instance']['awscli'] = '/usr/bin/aws'
else
  default['aws-vpc-nat-instance']['awscli'] = '/usr/local/bin/aws'
end

