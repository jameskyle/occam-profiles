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
# == Class: profile::openstack::firewall
#
# Creates firewall rules to protect mgmt network.
#
# === Parameters
# [mgmt_net_cidr]
#
# [public_net_cidr]
#
# [public_net_allocation_start]
#
# [public_net_allocation_end]
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
class profile::openstack::firewall (
  $mgmt_net_cidr = undef,
  $public_net_cidr = undef,
  $public_net_allocation_start = undef,
  $public_net_allocation_end = undef,
) {

  require_param($mgmt_net_cidr, '$mgmt_net_cidr')
  require_param($public_net_cidr, '$public_net_cidr')
  require_param($public_net_allocation_start, '$public_net_allocation_start')
  require_param($public_net_allocation_end, '$public_net_allocation_end')

  if $public_net_allocation_start and $public_net_allocation_end {
    firewall { '999 drop traffic from cloud to mgmt net':
        proto       => 'all',
        src_range   => "${public_net_allocation_start}-${public_net_allocation_end}",
        destination => $mgmt_net_cidr,
        action      => 'drop',
    }
  } else {
    firewall { '999 drop traffic from cloud to mgmt net':
        proto       => 'all',
        source      => $public_net_cidr,
        destination => $mgmt_net_cidr,
        action      => 'drop',
    }
  }

}
