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
# == Class: profile::tempest::setup
#
# Installs and configures tempest
#
# === Examples
#
#   include profile::tempest::setup
#
# === Authors
#
# Tomasz 'Zen' Napierala <tnapierala@mirantis.com>
# Kamil Swiatkowski <kswiatkowski@mirantis.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.

class profile::tempest::setup (
  $data_dir = '/var/lib/tempest_data',
  $cirros_uri = 'http://cdn.download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-uec.tar.gz',
  $cirros_bundle = 'cirros-0.3.1-x86_64-uec',
  $tempest_identity_uri = 'https://127.0.0.1:5000/v2.0/',
  $tempest_identity_uri_v3 = 'https://127.0.0.1:5000/v2.0/',
  $tempest_dashboard_url = 'https://127.0.0.1/horizon/',
) {

  include cinder::client
  include glance::client
  include keystone::client
  include neutron::client
  include nova::client

  if !defined(Package['python-pip']) {
    package { 'python-pip':
      ensure => latest,
    }
  }
  package { 'libffi-dev':
    ensure   => installed,
  }
  package { 'tox':
    ensure   => installed,
    provider => 'pip',
    require  => [ Package['python-pip'], Package['libffi-dev'] ],
  }
  $tempest_users = hiera('profile::tempest::users::keystone_user')

  # TODO: move to hiera
  file { $data_dir:
    ensure => directory,
  }

  exec { 'download-cirros':

    command  => "/usr/bin/wget ${cirros_uri}",
    creates  => "${data_dir}/${cirros_bundle}.tar.gz",
    cwd      => $data_dir,
    require  => File[$data_dir]
  }

  exec { 'untar-cirros':
    command => "/bin/tar xf ${data_dir}/${cirros_bundle}.tar.gz",
    cwd     => $data_dir,
    creates => "${data_dir}/${cirros_bundle}",
    require => Exec['download-cirros']
  }

  if $::cloud_available {

    class { 'tempest':
      tempest_repo_revision              => 'stable/havana',
      setup_venv                         => true,
      require                            => Package['tox'],
      configure_images                   => true,
      image_name                         => 'Cirros 0.3.1 amd64',
      image_name_alt                     => 'Cirros 0.3.1 amd64',
      configure_networks                 => true,
      public_network_name                => 'public',
      disable_ssl_certificate_validation => true,
      identity_uri                       => $tempest_identity_uri,
      identity_uri_v3                    => $tempest_identity_uri_v3,
      username                           => $tempest_users[demo][name],
      password                           => $tempest_users[demo][password],
      tenant_name                        => $tempest_users[demo][tenant],
      alt_username                       => $tempest_users[alt_demo][name],
      alt_password                       => $tempest_users[alt_demo][password],
      alt_tenant_name                    => $tempest_users[alt_demo][tenant],
      admin_username                     => 'admin',
      admin_password                     => hiera('profile::openstack::controller::admin_password'),
      admin_tenant_name                  => 'admin',
      flavor_ref                         => '1',
      flavor_ref_alt                     => '2',
      image_ssh_user                     => 'cirros',
      image_ssh_password                 => 'cubswin:)',
      image_alt_ssh_user                 => 'cirros',
      fixed_network_name                 => '',
      network_for_ssh                    => 'public',
      tenant_network_cidr                => '10.100.0.0/24',
      tenant_network_mask_bits           => '25',
      tenant_networks_reachable          => false,
      #public_router_id                   => ' ',
      dashboard_url                      => $tempest_dashboard_url,
      dash_login_url                     => "${tempest_dashboard_url}auth/login/",
      cli_dir                            => '/usr/bin/',
      scn_img_dir                        => "${data_dir}/${cirros_bundle}",
      cli_timeout                        => '30',
      cinder_available                   => true,
      neutron_available                  => true,
      glance_available                   => true,
      swift_available                    => false,
      nova_available                     => true,
      heat_available                     => false,
      horizon_available                  => true,
    }

  }
}

