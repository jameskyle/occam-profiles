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
# == Class: profile::openstack::network
#
# Creates floating ip range.
#
# === Parameters
# none
#
# === Examples
# TODO
#
# === Authors
#
# Tomasz Napierala <tnapierala@mirantis.com>
# Kamil Swiatkowski <kswiatkowski@mirantis.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.
class profile::openstack::network (
  $public_net_cidr = undef,
  $public_net_name = 'public',
  $public_net_gateway = undef,
  $public_net_allocation_start = undef,
  $public_net_allocation_end = undef,
) {

  if $::cloud_available {
    require_param($public_net_cidr, '$public_net_cidr')
    require_param($public_net_name, '$public_net_name')
    require_param($public_net_gateway, '$public_net_gateway')
    require_param($public_net_allocation_start, '$public_net_allocation_start')
    require_param($public_net_allocation_end, '$public_net_allocation_end')

    $os_password = hiera('profile::openstack::controller::admin_password')
    $os_auth_url = hiera('profile::openstack::compute::neutron_auth_url')

    neutron_network { $public_net_name:
      ensure                   => present,
      tenant_name              => 'admin',
      router_external          => true,
    }

    exec { "neutron subnet-create ${public_net_name}-subnet-1":
      command => "/usr/bin/neutron \
        --os-username admin \
        --os-password ${os_password} \
        --os-tenant-name admin \
        --os-auth-url ${os_auth_url} \
        subnet-create ${public_net_name} \
        --name ${public_net_name}-subnet-1 \
        --allocation-pool \
        start=${public_net_allocation_start},end=${public_net_allocation_end} \
        --gateway=${public_net_gateway} \
        --enable_dhcp=False ${public_net_cidr}",
      unless  => "/usr/bin/neutron \
        --os-username admin \
        --os-password ${os_password} \
        --os-tenant-name admin \
        --os-auth-url ${os_auth_url} \
        subnet-show ${public_net_name}-subnet-1",
      require => Neutron_network[$public_net_name]
    }
  }

}
