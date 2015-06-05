# aws-vpc-nat-instance-cookbook

This cookbook provides a library and recipes to configure and manage NAT instance in AWS cloud.
Currently supported features:
- configure EC2 instance to act as NAT instance.
- switch off source destination checking. 
- set a failover monitoring script.

## Supported Platforms

- Ubuntu 12.04
- Ubuntu 14.04

## AWS Credentials
In order to manage AWS components, authentication credentials need to be available to the node.
There are 2 ways to handle this:

1. explicitly pass credentials parameter to the resource.
2. let the cookbook pick up credentials from the IAM role assigned to the instance.

A recommended way is using IAM role.

### Using IAM instance role
Here is a sample policy for NAT instance:
```json
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "NATDescribeInstances",
            "Effect": "Allow",
            "Action": [
                 "ec2:DescribeInstanceStatus",
                 "ec2:DescribeInstances",
                 "ec2:DescribeInstanceRecoveryAttribute",
                 "ec2:DescribeTags",
                 "ec2:DescribeRouteTables"
            ],
            "Resource": "*"
        },
        {
            "Sid": "NATReplaceCreateRoute",
            "Effect": "Allow",
            "Action": [
                 "ec2:CreateRoute",
                 "ec2:ReplaceRoute"

            ],
            "Resource": "*"
        },
        {
            "Sid": "NATPublishSNSMessage",
            "Effect": "Allow",
            "Action": [
                 "sns:Publish"
            ],
            "Resource": [
                "arn:aws:sns:us-east-1:*:prod-nat-alerts"
            ]
        },
        {
            "Sid": "NATPutMetricAlarm",
            "Effect": "Allow",
            "Action": [
                 "cloudwatch:PutMetricAlarm"
            ],
            "Resource": "*"
        },
        {
            "Sid": "NATAutoRecovery",
            "Effect": "Allow",
            "Action": [
                 "ec2:RecoverInstances"
            ],
            "Resource": [
                "arn:aws:sns:us-east-1:*:prod-nat-alerts"
            ]
        }
    ]
}
```


## Attributes



<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['aws-vpc-nat-instance']['ipmasq_src']</tt></td>
    <td>String</td>
    <td>Which subnet to accept traffic from</td>
    <td><tt>10.0.0.0/16</tt></td>
  </tr>
  <tr>
    <td><tt>['aws-vpc-nat-instance']['interface']</tt></td>
    <td>String</td>
    <td>Output interface, probably to the internet</td>
    <td><tt>eth0</tt></td>
  </tr>  
  <tr>
    <td><tt>['aws-vpc-nat-instance']['access_key_id']</tt></td>
    <td>nil</td>
    <td>aws key</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['aws-vpc-nat-instance']['secret_access_key']</tt></td>
    <td>String</td>
    <td>aws secret</td>
    <td><tt>nil</tt></td>
  </tr>
  <tr>
    <td><tt>['aws-vpc-nat-instance']['disable_source_dest_check']</tt></td>
    <td>String</td>
    <td>Disable source dest check</td>
    <td><tt>true</tt></td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['auto_recovery']['enabled']</tt></td>
    <td>Boolean</td>
    <td>Enable NAT instance auto recovery via CloudWatch alarm</td>
    <td><tt>false</tt></td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['monitor']['enabled']</tt></td>
    <td>Boolean</td>
    <td>Enable monitoring recipe</td>
    <td><tt>true</tt></td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['monitor']['default_environment_name']</tt></td>
    <td>String</td>
    <td>Monitoring recipe relies on special naming convention for NAT instance and route tables names (see the 
    library source code for details).  The attribute is a mapping between Chef's `_default` environment and AWS
    environment.</td>
    <td><tt>prod</tt></td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['monitor']['sns_enabled']</tt></td>
    <td>Boolean</td>
    <td>Enable NAT alerts notifications via SNS</td>
    <td><tt>false</tt></td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['monitor']['sns_arn']</tt></td>
    <td>String</td>
    <td>ARN of SNS topic</td>
    <td><tt>nil</tt></td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['monitor']['install_dir']</tt></td>
    <td>String</td>
    <td>Installation directory for monitoring script</td>
    <td><tt>/opt/nat_monitor</tt></td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['monitor']['user']</tt></td>
    <td>String</td>
    <td>A user to run monitoring script. </td>
    <td><tt>natadm</tt></td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['monitor']['internet_access_test_ip']</tt></td>
    <td>String</td>
    <td>A public Internet address used for Internet connectivity self-check</td>
    <td><tt>8.8.4.4</tt></td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['monitor']['number_of_pings']</tt></td>
    <td>String</td>
    <td>A number of pings during health checks</td>
    <td><tt>3</tt></td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['monitor']['ping_timeout']</tt></td>
    <td>String</td>
    <td>A timeout for ping</td>
    <td><tt>2s</tt></td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['monitor']['wait_between_checks']</tt></td>
    <td>String</td>
    <td>A delay between health check cycles</td>
    <td><tt>10s</tt></td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['monitor']['az'][`{availability_zone}`]['opposite_zone']</tt></td>
    <td>String</td>
    <td>An ID of an opposite availability zone to monitor health of NAT instance</td>
    <td>Default pairs are:
        <ul>
        <li>'us-east-1b' - 'us-east-1c'</li>
        <li>'us-east-1d' - 'us-east-1e'</li>
        </ul>
    </td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['jq']</tt></td>
    <td>String</td>
    <td>A path to JQ binary</td>
    <td><tt>/usr/bin/jq</tt></td>
  </tr>
  tr>
    <td><tt>['aws-vpc-nat-instance']['awscli']</tt></td>
    <td>String</td>
    <td>A path to AWSCLI tools binary</td>
    <td><tt>/usr/local/bin/aws</tt></td>
  </tr>
</table>

## Usage

### aws-vpc-nat-instance::default

Include `aws-vpc-nat-instance` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[aws-vpc-nat-instance::default]"
  ]
}
```

## License and Authors

* Author:: Will Salt (<williamejsalt@gmail.com>)
* Author:: Sasha Zhukau (<sasha.zhukau@rubikloud.com>)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
