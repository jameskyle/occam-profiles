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
# == Class: profile::openstack::ceilometer::compute
#
# Configures ceilometer agent on compute node.
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
class profile::openstack::ceilometer::compute (
  $mgmt_ctrl_ip         = undef,
  $ceilometer_auth_url  = undef,
  $service_password     = 'secret_password',
  $metering_secret      = 'secret_ceilometer_password',
  $rabbit_user          = 'openstack',
  $rabbit_password      = undef,
  $ha                   = false,
  $controllers_name     = undef,
) {

  require_param($mgmt_ctrl_ip, '$mgmt_ctrl_ip')
  require_param($rabbit_password, '$rabbit_password')

  $ceilometer_auth_url_real = get_real($ceilometer_auth_url,
    "http://${mgmt_ctrl_ip}:35357/v2.0"
  )

  $controllers_name_sorted = sort($controllers_name)
  $ha_config = str2bool($ha)

  if ($ha_config) {
    $rabbit_hosts = $controllers_name_sorted
  } else {
    $rabbit_hosts = undef
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

  # Set common auth parameters used by all agents (compute/central)
  class { '::ceilometer::agent::auth':
    auth_url      => $ceilometer_auth_url_real,
    auth_password => $service_password,
  }

  # Install compute agent
  # default: enable
  class { 'ceilometer::agent::compute':
  }

  cron { 'cinder-volume-usage-audit':
    command => 'cinder-volume-usage-audit 1>/dev/null',
    user    => 'root',
    minute  => '0',
    require => Package['cinder-volume']
  }

}
