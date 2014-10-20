###############################################################################
##                                                                           ##
## The MIT License (MIT)                                                     ##
##                                                                           ##
## Copyright (c) 2014 AT&T Inc.                                              ##
##                                                                           ##
## Permission is hereby granted, free of charge, to any person obtaining     ##
## a copy of this software and associated documentation files                ##
## (the "Software"), to deal in the Software without restriction, including  ##
## without limitation the rights to use, copy, modify, merge, publish,       ##
## distribute, sublicense, and/or sell copies of the Software, and to permit ##
## persons to whom the Software is furnished to do so, subject to the        ##
## conditions as detailed in the file LICENSE.                               ##
##                                                                           ##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS   ##
## OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                ##
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.    ##
## IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY      ##
## CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT ##
## OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR  ##
## THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                ##
##                                                                           ##
###############################################################################
# == Class: profile::openstack::swift::proxy
#
# Configures swift proxy.
#
# === Authors
#
# Piotr Misiak <pmisiak@mirantis.com>
#
# === Copyright
#
# Copyright 2014 AT&T Foundry, unless otherwise noted.
class profile::openstack::swift::proxy (
  $swift_hash_suffix      = 'swift_hash_suffix',
  $part_power             = '18',
  $replicas               = '3',
  $min_part_hours         = '1',
  $dispersion_coverage    = '1',
  $dispersion_retries     = '5',
  $dispersion_concurrency = '25',
  $dispersion_dump_json   = 'no',
  $dispersion_username    = 'swift_dispersion',
  $dispersion_password    = 'dispersion_password',
  $service_username       = 'swift',
  $service_password       = 'swift_password',
  $public_protocol        = 'https',
  $public_port            = '8080',
  $public_address         = undef,
  $internal_protocol      = 'http',
  $mgmt_ctrl_ip           = undef,
  $internal_port          = '8080',
  $proxy_pipeline         = ['healthcheck', 'catch_errors', 'cache', 'authtoken', 'keystone', 'proxy-server'],
  $proxy_workers          = $::processorcount,
  $proxy_bind_port        = '8081',
  $priv_interface         = undef,
  $mgmt_interface         = undef,
  $proxies_ip             = undef,
  $storages_ip            = undef,
  $log_facility           = 'local4',
  $conntrack_size         = '655360',
  $operator_roles         = ['admin', 'SwiftOperator', '_member_'],
) {

  require_param($public_address, '$public_address')
  require_param($mgmt_ctrl_ip, '$mgmt_ctrl_ip')
  require_param($priv_interface, '$priv_interface')
  require_param($mgmt_interface, '$mgmt_interface')
  require_param($proxies_ip, '$proxies_ip')

  $mgmt_local_ip = inline_template(
    "<%= scope.lookupvar('ipaddress_${mgmt_interface}') %>"
  )

  $priv_local_ip = inline_template(
    "<%= scope.lookupvar('ipaddress_${priv_interface}') %>"
  )

  $log_facility_uppercase = upcase($log_facility)
  $log_facility_lowercase = downcase($log_facility)

  $proxies_ip_sorted = sort($proxies_ip)
  $master_ctrl_ip = $proxies_ip_sorted[0]

  $storages_count = size($storages_ip)

  if ($storages_count > 0) {

    sysctl::value { 'net.netfilter.nf_conntrack_max':
      value   => $conntrack_size,
    }

    class { 'swift':
      swift_hash_suffix => $swift_hash_suffix,
    }

    class { 'swift::keystone::auth':
      auth_name         => $service_username,
      password          => $service_password,
      public_protocol   => $public_protocol,
      public_port       => $public_port,
      public_address    => $public_address,
      port              => $internal_port,
      admin_address     => $mgmt_ctrl_ip,
      admin_protocol    => $internal_protocol,
      internal_address  => $mgmt_ctrl_ip,
      internal_protocol => $internal_protocol,
      operator_roles    => $operator_roles,
    }

    class { 'swift::keystone::dispersion':
      auth_user => $dispersion_username,
      auth_pass => $dispersion_password,
    }

    if ( $master_ctrl_ip == $mgmt_local_ip ) {
      # create rings
      class { 'swift::ringbuilder':
        part_power     => $part_power,
        replicas       => $replicas,
        min_part_hours => $min_part_hours,
        before         => Class[::swift::proxy]
      }
      # add devices to rings
      Ring_object_device <<| |>>
      Ring_container_device <<| |>>
      Ring_account_device <<| |>>
      # share rings - rsync server
      class { 'swift::ringserver':
        local_net_ip => $master_ctrl_ip,
      }
    } else {
      # synchronize rings with master proxy
      swift::ringsync { ['account', 'container', 'object']:
        ring_server => $master_ctrl_ip,
        before      => Class[::swift::proxy]
      }
    }

    proxy_server_pipeline_includer { $proxy_pipeline:
      keystone_endpoint_ip  => $mgmt_ctrl_ip,
      service_username      => $service_username,
      service_password      => $service_password,
      operator_roles        => $operator_roles,
    }

    class { '::swift::proxy':
      proxy_local_net_ip  => $priv_local_ip,
      port                => $proxy_bind_port,
      workers             => $proxy_workers,
      pipeline            => $proxy_pipeline,
      log_facility        => "LOG_${log_facility_uppercase}",
      require             => Class['swift'],
    }

    file {'/etc/rsyslog.d/10-swift-proxy-server.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "${log_facility_lowercase}.* /var/log/swift/proxy-server.log\n& ~\n",
      require => Class['::swift::proxy'],
      notify  => Exec['restart rsyslog'],
    }

    exec {'restart rsyslog':
      refreshonly => true,
    }

    @@haproxy::balancermember {"swift-${::fqdn}":
      listening_service => 'swift',
      ipaddresses       => $priv_local_ip,
      ports             => $proxy_bind_port,
    }

    class { 'swift::dispersion':
      auth_url      => "http://${$mgmt_ctrl_ip}:5000/v2.0/",
      auth_user     => $dispersion_username,
      auth_pass     => $dispersion_password,
      coverage      => $dispersion_coverage,
      retries       => $dispersion_retries,
      concurrency   => $dispersion_concurrency,
      dump_json     => $dispersion_dump_json,
      require       => [ Class['swift'], Class['::swift::proxy'] ]
    }

    file{'/etc/facter/facts.d/swift.sh':
      ensure  => present,
      content => template('profile/facts/swift.sh.erb'),
      mode    => '0700',
      owner   => root,
      require => [ Class['swift'], File['/etc/facter/facts.d'] ],
    }
  }
}
