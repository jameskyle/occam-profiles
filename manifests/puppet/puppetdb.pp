# Class: profile::puppet::puppetdb
#
#
class profile::puppet::puppetdb {
  class { '::puppetdb':
    ssl_listen_address => '0.0.0.0',
    java_args          => { '-Xmx' => '4g' }
  }
  class{ '::puppetdb::master::config': }
}