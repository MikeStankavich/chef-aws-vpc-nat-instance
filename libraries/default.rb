module AwsVpcNatInstance
  module Helper

    # borrowed from https://github.com/opscode-cookbooks/aws/blob/master/libraries/ec2.rb

    def ec2
      @@ec2 ||= create_aws_interface(::Aws::EC2::Client)
    end

    def instance_availability_zone
      @@instance_availability_zone ||= node['ec2']['placement_availability_zone']
    end

    def region
      @@region ||= instance_availability_zone[0..-2]
    end

    def instance_id
      @@instance_id ||= node['ec2']['instance_id']
    end

    def environment
      if node['chef_environment'] == '_default'
        @@environment = node['aws-vpc-nat-instance']['default_environment_name']
      else
        @@environment = node['chef_environment']
      end
    end

    def disable_source_dest
      ec2.modify_instance_attribute(
          instance_id: instance_id,
          source_dest_check: {
              value: false,
          },
      )
    end

    def get_opposite_primary_nat_id(az)
      resp = ec2.describe_instances(
          filters: [
              {name:'instance-state-name', values:['running']},
              {name:'tag:Name', values:["#{environment}-nat-#{az}-*"]},
              {name:'availability-zone', values:[az]}
          ]
      )
      id  ||= resp.reservations.first.instances.first.instance_id
      return id
    end

    def get_opposite_rtb_id(az)
      resp = ec2.describe_route_tables(
          filters: [
              {name:'tag:Name', values:["#{environment}-rtb-private-#{az}"]}
          ]
      )
      id ||= resp.route_tables.first.route_table_id
      return id
    end

    private

		def create_aws_interface(aws_interface)
			begin
				require 'aws-sdk'
			rescue LoadError
				Chef::Log.error("Missing gem 'aws-sdk'. Use the default aws recipe to install it first.")
			end

			aws_interface.new(region: region)
		end

  end
end
