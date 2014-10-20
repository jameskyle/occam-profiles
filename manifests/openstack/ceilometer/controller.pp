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
# == Class: profile::openstack::ceilometer::controller
#
# Configures ceilometer on a controller node.
#
# === Parameters
# TODO
#
# === Examples
# TODO
#
# === Authors
#
# Piotr Misiak <pmisiak@mirantis.com>
#
# === Copyright
#
# Copyright 2014 AT&T Foundry, unless otherwise noted.
class profile::openstack::ceilometer::controller (
  $mgmt_ctrl_ip         = undef,
  $pub_ctrl_ip          = undef,
  $ceilometer_auth_url  = undef,
  $public_url           = undef,
  $bind_host            = '127.0.0.1',
  $service_password     = 'secret_password',
  $db_password          = 'db_password',
  $metering_secret      = 'secret_ceilometer_password',
  $rabbit_user          = 'openstack',
  $rabbit_password      = undef,
  $ttl                  = '2592000',
  $ha                   = false,
  $controllers_name     = undef,
  $ceilometer_blkdev    = undef,
) {

  require_param($mgmt_ctrl_ip, '$mgmt_ctrl_ip')
  require_param($pub_ctrl_ip, '$pub_ctrl_ip')
  require_param($rabbit_password, '$rabbit_password')

  $ceilometer_auth_url_real = get_real($ceilometer_auth_url,
    "http://${mgmt_ctrl_ip}:35357/v2.0"
  )

  $public_url_real = get_real($public_url,"https://${pub_ctrl_ip}:8777")

  $controllers_name_sorted = sort($controllers_name)
  $master_ctrl_name = controllers_name_sorted[0]
  $ha_config = str2bool($ha)

  if ($master_ctrl_name == $::hostname) {
    $on_master_ctrl = true
  } else {
    $on_master_ctrl = false
  }

  if ($ha_config) {
    $rabbit_hosts = $controllers_name_sorted
  } else {
    $rabbit_hosts = undef
  }

  if (!$ha_config or ($ha_config and $on_master_ctrl)) {

    # Create and mount dedicated partition for mongodb files if ceilometer_blkdev is defined
    if ( $ceilometer_blkdev != undef ) {
      exec { "fstab ${ceilometer_blkdev}":
        command => "echo '${ceilometer_blkdev} /var/lib/mongodb  ext4  defaults  0 2' >> /etc/fstab",
        unless  => "grep  ${ceilometer_blkdev} /etc/fstab",
        path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
        before  => Class['::mongodb'],
        notify  => Exec["mkfs.ext4 ${ceilometer_blkdev}"],
      }
      exec { "mkfs.ext4 ${ceilometer_blkdev}":
        command     => "mkfs.ext4 ${ceilometer_blkdev}",
        path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
        before      => Class['::mongodb'],
        refreshonly => true,
        notify      => Exec["mount ${ceilometer_blkdev}"],
      }
      exec { "mount ${ceilometer_blkdev}":
        command     => 'mkdir -p /var/lib/mongodb && mount /var/lib/mongodb',
        path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
        before      => Class['::mongodb'],
        refreshonly => true,
      }
    }

    # Create user, service and endpoints in Keystone
    class { '::ceilometer::keystone::auth':
      password          => $service_password,
      public_url        => $public_url_real,
      admin_address     => $mgmt_ctrl_ip,
      internal_address  => $mgmt_ctrl_ip,
    }

    # Add the base ceilometer class & parameters
    # This class is required by ceilometer agents & api classes
    # The metering_secret parameter is mandatory
    class { '::ceilometer':
      metering_secret => $metering_secret,
      rabbit_host     => $mgmt_ctrl_ip,
      rabbit_hosts    => $rabbit_hosts,
      rabbit_userid   => $rabbit_user,
      rabbit_password => $rabbit_password,
    }

    # Configure ceilometer database with mongodb
    include mongodb
    class { '::ceilometer::db':
      database_connection => 'mongodb://localhost:27017/ceilometer',
      require             => Class['::mongodb'],
    }

    # Install the ceilometer-api service
    # The keystone_password parameter is mandatory
    class { '::ceilometer::api':
      keystone_password => $service_password,
      keystone_host     => $mgmt_ctrl_ip,
      host              => $bind_host,
    }

    # Set common auth parameters used by all agents (compute/central)
    class { '::ceilometer::agent::auth':
      auth_url      => $ceilometer_auth_url_real,
      auth_password => $service_password,
    }

    # Install central agent
    class { '::ceilometer::agent::central':
    }

    # Install ceilometer collector
    class { '::ceilometer::collector':
    }

    # Install ceilometer client
    class { '::ceilometer::client':
    }

    # Purge 1 month old meters
    class { '::ceilometer::expirer':
      time_to_live => $ttl
    }

    # Install alarm notifier (IceHouse)
    #class { '::ceilometer::alarm::notifier':
    #}

    # Install alarm evaluator (IceHouse)
    #class { '::ceilometer::alarm::evaluator':
    #}


    # Install notification agent (IceHouse)
    #class { '::ceilometer::agent::notification':
    #}

  }

}
