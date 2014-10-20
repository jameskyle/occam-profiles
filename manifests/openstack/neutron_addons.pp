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
# == Class: profile::openstack::neutron_addons
#
# Configures neutron additional parameters.
#
# === Parameters
# TODO
#
# === Examples
# TODO
#
# === Authors
#
# Kamil Swiatkowski <kswiatkowski@mirantis.com>
#
# === Copyright
#
# Copyright 2014 AT&T Foundry, unless otherwise noted.
class profile::openstack::neutron_addons (
  $instance_mtu = '1500',
  $external_dns = '8.8.8.8',
  $database_max_pool_size = 50
) {

  neutron_dhcp_agent_config {
    'DEFAULT/dnsmasq_config_file': value => '/etc/neutron/dnsmasq-neutron.conf';
  }

  neutron_dhcp_agent_config {
    'DEFAULT/dnsmasq_dns_server': value => $external_dns;
  }

  file { '/etc/neutron/dnsmasq-neutron.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => 'dhcp-option-force=26,1400',
    require => Package['neutron-server'],
    notify  => Service['neutron-dhcp-service'],
  }

  neutron_config {
    'database/max_pool_size': value => $database_max_pool_size;
  }

}
