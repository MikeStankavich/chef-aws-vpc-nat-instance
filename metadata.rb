name             'aws-vpc-nat-instance'
maintainer       'Will Salt'
maintainer_email 'williamejsalt@gmail.com'
license          'Apache 2.0'
description      'Installs/Configures aws-vpc-nat-instance'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.0'

depends 'simple_iptables', '= 0.7.1'
depends 'sysctl', '= 0.6.2'
depends 'chef-sugar', '= 3.0.1'
depends 'supervisor', '~> 0.4.12'
depends 'awscli', '~> 1.1.1'