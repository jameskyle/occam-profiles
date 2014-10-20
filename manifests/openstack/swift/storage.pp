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
# == Class: profile::openstack::swift::storage
#
# Configures swift storage
#
# === Authors
#
# Piotr Misiak <pmisiak@mirantis.com>
#
# === Copyright
#
# Copyright 2014 AT&T Foundry, unless otherwise noted.
class profile::openstack::swift::storage (
  $swift_hash_suffix      = 'swift_hash_suffix',
  $storage_device         = '/dev/sda6',
  $storage_dir            = '/srv/node',
  $allow_versions         = false,
  $mount_check            = false,
  $object_port            = '6000',
  $container_port         = '6001',
  $account_port           = '6002',
  $priv_interface         = undef,
  $proxies_ip             = undef,
  $zones                  = '5',
  $weight                 = '1',
  $replicator_concurrency = '1',
  $updater_concurrency    = '1',
  $reaper_concurrency     = '1',
  $log_facility           = 'local4',
  $object_workers         = $::processorcount,
  $container_workers      = $::processorcount,
  $account_workers        = $::processorcount,
  $conntrack_size         = '655360',
) {

  require_param($priv_interface, '$priv_interface')
  require_param($proxies_ip, '$proxies_ip')

  $priv_local_ip = inline_template(
    "<%= scope.lookupvar('ipaddress_${priv_interface}') %>"
  )

  $storage_device_name = regsubst($storage_device,'.*\/(\w+)$','\1')

  $log_facility_uppercase = upcase($log_facility)
  $log_facility_lowercase = downcase($log_facility)

  $proxies_ip_sorted = sort($proxies_ip)
  $master_ctrl_ip = $proxies_ip_sorted[0]
  $proxies_count = size($proxies_ip)

  if ($proxies_count > 0) {

    sysctl::value { 'net.netfilter.nf_conntrack_max':
      value   => $conntrack_size,
    }

    class { 'swift':
      swift_hash_suffix => $swift_hash_suffix,
    }

    swift::ringsync { ['account', 'container', 'object']:
      ring_server => $master_ctrl_ip,
    }

    swift::storage::xfs { $storage_device_name:
      mnt_base_dir => $storage_dir,
    }

    class { '::swift::storage':
      storage_local_net_ip => $priv_local_ip,
    }

    Swift::Storage::Server {
      devices                 => $storage_dir,
      storage_local_net_ip    => $priv_local_ip,
      mount_check             => $mount_check,
      replicator_concurrency  => $replicator_concurrency,
      updater_concurrency     => $updater_concurrency,
      reaper_concurrency      => $reaper_concurrency,
      require                 => Class['swift'],
    }

    Swift::Ringsync<| |> -> Swift::Storage::Server<| |>

    swift::storage::server { $account_port:
      type              => 'account',
      config_file_path  => 'account-server.conf',
      log_facility      => "LOG_${log_facility_uppercase}",
      workers           => $account_workers,
    }

    swift::storage::server { $container_port:
      type              => 'container',
      config_file_path  => 'container-server.conf',
      log_facility      => "LOG_${log_facility_uppercase}",
      allow_versions    => $allow_versions,
      workers           => $container_workers,
    }

    swift::storage::server { $object_port:
      type              => 'object',
      config_file_path  => 'object-server.conf',
      log_facility      => "LOG_${log_facility_uppercase}",
      workers           => $object_workers,
    }

    file {'/etc/rsyslog.d/10-swift-storage.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "${log_facility_lowercase}.* /var/log/swift/storage-servers.log\n& ~\n",
      require => Class['::swift::storage'],
      notify  => Exec['restart rsyslog'],
    }

    exec {'restart rsyslog':
      refreshonly => true,
    }

  }

  $node_number = regsubst($::hostname,'.*?(\d+)$','\1')
  $node_zero_based = $node_number - 1
  $zone_zero_based = $node_zero_based % $zones
  $zone = $zone_zero_based + 1

  @@ring_object_device { "${priv_local_ip}:${object_port}/${storage_device_name}":
    zone    => $zone,
    weight  => $weight,
  }

  @@ring_container_device { "${priv_local_ip}:${container_port}/${storage_device_name}":
    zone    => $zone,
    weight  => $weight,
  }

  @@ring_account_device { "${priv_local_ip}:${account_port}/${storage_device_name}":
    zone    => $zone,
    weight  => $weight,
  }

}
