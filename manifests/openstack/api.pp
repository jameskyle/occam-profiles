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
# == Class: profile::openstack::api::nova
#
# Creates a proxy backend entry for the openstack api's.
# API's Include:
#   - dashboard
#   - compute
#   - network
#   - image
#   - volume
#   - ec2
#   - auth
#
# === Parameters
# [service_address]
#   The source address to proxy. This is often, but not always, the $::ipaddress
#   of the registering service.
#
# === Examples
#
#  class {'profile::openstack::api':
#    service_address => $::ipaddress,
#  }
#
# === Authors
#
# James Kyle <james@jameskyle.org>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.

class profile::openstack::api (
  $service_address = undef,
  $loopback_address = '127.0.0.1',
) {

  @@haproxy::balancermember {"horizon-${::fqdn}":
    listening_service => 'horizon',
    ipaddresses       => $service_address,
    ports             => '80',
  }
  @@haproxy::balancermember {"novnc-${::fqdn}":
    listening_service => 'novnc',
    ipaddresses       => $service_address,
    ports             => '6080',
  }
  @@haproxy::balancermember {"glance-${::fqdn}":
    listening_service => 'glance',
    ipaddresses       => $service_address,
    ports             => '9292',
  }
  @@haproxy::balancermember {"ec2-${::fqdn}":
    listening_service => 'ec2',
    ipaddresses       => $service_address,
    ports             => '8773',
  }
  @@haproxy::balancermember {"nova-${::fqdn}":
    listening_service => 'nova',
    ipaddresses       => $service_address,
    ports             => '8774',
  }
  @@haproxy::balancermember {"keystone-${::fqdn}":
    listening_service => 'keystone',
    ipaddresses       => $service_address,
    ports             => '5000',
  }
  @@haproxy::balancermember {"keystone_admin-${::fqdn}":
    listening_service => 'keystone_admin',
    ipaddresses       => $service_address,
    ports             => '35357',
  }
  @@haproxy::balancermember {"cinder-${::fqdn}":
    listening_service => 'cinder',
    ipaddresses       => $service_address,
    ports             => '8776',
  }
  @@haproxy::balancermember {"neutron-${::fqdn}":
    listening_service => 'neutron',
    ipaddresses       => $service_address,
    ports             => '9696',
  }
  @@haproxy::balancermember {"savanna-${::fqdn}":
    listening_service => 'savanna',
    ipaddresses       => $service_address,
    ports             => '8386',
  }
  @@haproxy::balancermember {"ceilometer-${::fqdn}":
    listening_service => 'ceilometer',
    ipaddresses       => $service_address,
    ports             => '8777',
  }
  @@haproxy::balancermember {"rabbit-${::fqdn}":
    listening_service => 'rabbit',
    ipaddresses       => $service_address,
    ports             => '5672',
  }
  @@haproxy::balancermember {"metadata-${::fqdn}":
    listening_service => 'metadata',
    ipaddresses       => $service_address,
    ports             => '8775',
  }
}
