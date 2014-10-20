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
# == Class: profile::openstack::savanna
#
# Configures savanna components
#
# === Parameters
# TODO
#
# === Examples
# TODO
#
# === Authors
#
# Tomasz Z. Napierala <tnapierala@mirantis.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.

class profile::openstack::savanna (
  $plugins                   = ['vanilla', 'hdp'],
  $db_host                   = '127.0.0.1',
  $db_pass                   = 'savanna',
  # password for savanna user in keystone
  $keystone_pass             = 'savanna',
  $keystone_tenant           = 'services',
  $keystone_auth_protocol    = 'http',
  $keystone_auth_host        = '127.0.0.1',
  $keystone_auth_port        = '5000',
  $setup_keystone            = true,
  # savanna addresses in keystone
  $endpoint_public_address   = 'mapreduce.cloud.domain.com',
  $endpoint_admin_address    = '127.0.0.1',
  $endpoint_internal_address = '127.0.0.1',
  # savanna API address
  $savanna_address           = '127.0.0.1',
  # savanna bind address
  $savanna_bind_address      = '127.0.0.1',
) {

  if $::cloud_available {

    class { 'savanna::db::mysql': password => $db_pass, }
  # Already implemented in puppet-openstack/manifests/keystone.pp
    if $setup_keystone {
      class { 'savanna::keystone::auth':
        password         => $keystone_pass,
        public_address   => $endpoint_public_address,
        admin_address    => $endpoint_admin_address,
        internal_address => $endpoint_internal_address,
        tenant           => $keystone_tenant,
        public_protocol  => 'https',
      }
    }
    if ! defined(Apt::Ppa['ppa:tzn/savanna-0.3']) {
      apt::ppa { 'ppa:tzn/savanna-0.3': }
    }
    class { '::savanna':
      plugins                 => $plugins,
      savanna_host            => $savanna_bind_address,
      db_host                 => $db_host,
      savanna_db_password     => $db_pass,
      keystone_auth_protocol  => $keystone_auth_protocol,
      keystone_auth_host      => $keystone_auth_host,
      keystone_auth_port      => $keystone_auth_port,
      keystone_password       => $keystone_pass,
      savanna_verbose         => true,
      require                 => [Class['savanna::db::mysql'], Apt::Ppa['ppa:tzn/savanna-0.3']]
    }
    class { 'savanna::dashboard':
      savanna_host => $savanna_address,
      use_neutron  => true,
      require      => [Class['openstack::horizon'], Apt::Ppa['ppa:tzn/savanna-0.3']]
    }

  }

}
