module AwsVpcNatInstance
  module Helper

    # borrowed from https://github.com/opscode-cookbooks/aws/blob/master/libraries/ec2.rb

    def ec2
      begin
        require 'aws-sdk'
      rescue LoadError
        Chef::Log.error("Missing gem 'aws-sdk'. Use the default aws recipe to install it first.")
      end

      @@ec2 ||= create_aws_interface(::Aws::EC2::Client)
    end

    def cloudwatch
      @@cloudwatch ||= create_aws_interface(::Aws::CloudWatch::Client)
    end

    def get_instance_availability_zone
      @@instance_availability_zone ||= node['ec2']['placement_availability_zone']
    end

    def get_region
      @@region ||= get_instance_availability_zone[0..-2]
    end

    def get_instance_id
      @@instance_id ||= node['ec2']['instance_id']
    end

    def get_instance_private_ip
      @@instance_private_ip ||= node['ec2']['local_ipv4']
    end

    def get_environment
      if node.chef_environment == '_default'
        @@environment = node['aws-vpc-nat-instance']['monitoring']['default_environment_name']
      else
        @@environment = node.chef_environment
      end
    end

    def disable_source_dest
      ec2.modify_instance_attribute(
          instance_id: get_instance_id,
          source_dest_check: {
              value: false,
          },
      )
    end

    def get_nat_id(az)
      states = %w(running pending stopping stopped)
      resp = ec2.describe_instances(
          filters: [
              {name:'instance-state-name', values: states},
              {name:'tag:Name', values:["#{get_environment}-nat-#{az}-*"]},
              {name:'availability-zone', values:[az]}
          ]
      )
      id  ||= resp.reservations.first.instances.first.instance_id
      return id
    end

    def get_rtb_id(az)
      resp = ec2.describe_route_tables(
          filters: [
              {name:'tag:Name', values:["#{get_environment}-rtb-private-#{az}"]}
          ]
      )
      id ||= resp.route_tables.first.route_table_id
      return id
    end

    def enable_nat_auto_recovery
      environment = get_environment
      region = get_region
      instance_id = get_instance_id
      resp = cloudwatch.put_metric_alarm(
          alarm_name: "#{environment}-nat-autorecovery",
          alarm_description: "NAT Instance autorecovery in #{environment} environment",
          alarm_actions: ["arn:aws:automate:#{region}:ec2:recover"],
          metric_name: 'StatusCheckFailed_System',
          namespace: 'AWS/EC2',
          statistic: 'Average',
          dimensions: [
              {
                  name: 'InstanceId',
                  value: instance_id,
              },
          ],
          period: 60,
          unit: 'Seconds',
          evaluation_periods: 2,
          threshold: 0,
          comparison_operator: 'GreaterThanThreshold',
      )
      resp
    end

    private

		def create_aws_interface(aws_interface)
			aws_interface.new(region: get_region)
		end

  end
end
