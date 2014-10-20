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
# == Class: profile::openstack::facts
#
# Distributes custom facts
#
# === Parameters
# TODO
#
# === Examples
# TODO
#
# === Authors
#
# Damian Szeluga <dszeluga@mirantis.com>
#
# === Copyright
#
# Copyright 2014 AT&T Foundry, unless otherwise noted.

class profile::openstack::facts {
  $keystone = hiera('profile::openstack::proxy::keystone_url')
  $nova     = hiera('profile::openstack::proxy::nova_url')
  $cinder   = hiera('profile::openstack::proxy::cinder_url')
  $glance   = hiera('profile::openstack::proxy::glance_url')
  $neutron  = hiera('profile::openstack::proxy::neutron_url')

  file{'/etc/facter/facts.d/cloud_urls.rb':
    ensure  => present,
    content => template('profile/facts/cloud.rb.erb'),
    mode    => '0755',
    require => File['/etc/facter/facts.d'],
  }

  file{'/etc/facter/facts.d':
    ensure  => directory,
    require => File['/etc/facter'],
  }

  file{'/etc/facter':
    ensure  => directory,
  }
}
