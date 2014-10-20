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
# == Class: profile::openstack::glanceimages
#
# Uploads base set of images to glance.
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
# Copyright 2013 AT&T Foundry, unless otherwise noted.
class profile::openstack::glanceimages {
  $glance_backend = hiera('profile::openstack::controller::glance_backend')

  ## workaround for self-signed certificate
  ## to be removed in the future

  #file { 'custom_glanceclient':
  #  ensure => present,
  #  path   => '/root/python-glanceclient_0.11.0-1ubuntu1insecure~cloud0_all.deb',
  #  source => 'puppet:///modules/profile/glanceimages/python-glanceclient_0.11.0-1ubuntu1insecure~cloud0_all.deb',
  #  notify => Exec['install_custom_glanceclient'],
  #}

  #exec { 'install_custom_glanceclient':
  #  command     => '/usr/bin/dpkg -i /root/python-glanceclient_0.11.0-1ubuntu1insecure~cloud0_all.deb',
  #  refreshonly => true,
  #  require     => Package['glance'],
  #}

  ## end of workaround

  if $glance_backend == 'file' {
    $run = true
  } elsif $glance_backend == 'swift' and str2bool($::swift_available) {
    $run = true
  } elsif $glance_backend == 'swift' and ! str2bool($::swift_available) {
    $run = false
  } else {
    fail("Unsupported glance backend")
  }

  if (str2bool($::cloud_available) and $run) {

    glance_image { 'Ubuntu 12.04 cloudimg amd64':
      ensure           => present,
      name             => 'Ubuntu 12.04 cloudimg amd64',
      is_public        => 'yes',
      container_format => 'bare',
      disk_format      => 'qcow2',
      source           => 'http://uec-images.ubuntu.com/releases/precise/release/ubuntu-12.04-server-cloudimg-amd64-disk1.img',
      require          => [Service['glance-api'], Service['keystone']],
      #require          => Exec['install_custom_glanceclient'],
    }

    glance_image { 'Ubuntu 13.10 cloudimg amd64':
      ensure           => present,
      name             => 'Ubuntu 13.10 cloudimg amd64',
      is_public        => 'yes',
      container_format => 'bare',
      disk_format      => 'qcow2',
      source           => 'http://uec-images.ubuntu.com/releases/saucy/release/ubuntu-13.10-server-cloudimg-amd64-disk1.img',
      require          => [Service['glance-api'], Service['keystone']],
      #require          => Exec['install_custom_glanceclient'],
    }

    glance_image { 'Cirros 0.3.1 amd64':
      ensure           => present,
      name             => 'Cirros 0.3.1 amd64',
      is_public        => 'yes',
      container_format => 'bare',
      disk_format      => 'qcow2',
      source           => 'http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img',
      require          => [Service['glance-api'], Service['keystone']],
      #require          => Exec['install_custom_glanceclient'],
    }

    glance_image { 'Centos 6.5 amd64':
      ensure           => present,
      name             => 'Centos 6.5 amd64',
      is_public        => 'yes',
      container_format => 'bare',
      disk_format      => 'qcow2',
      source           => 'http://repos.fedorapeople.org/repos/openstack/guest-images/centos-6.5-20140117.0.x86_64.qcow2',
      require          => [Service['glance-api'], Service['keystone']],
      #require          => Exec['install_custom_glanceclient'],
    }

    glance_image { 'Sahara 0.3 Vanilla 1.2.1 Ubuntu 13.04':
      ensure           => present,
      name             => 'sahara-0.3-vanilla-1.2.1-ubuntu-13.04',
      is_public        => 'yes',
      container_format => 'bare',
      disk_format      => 'qcow2',
      source           => 'http://sahara-files.mirantis.com/savanna-0.3-vanilla-1.2.1-ubuntu-13.04.qcow2',
      require          => [Service['glance-api'], Service['keystone']],
    }

    glance_image { 'Sahara 0.3 HDP 1.3 Centos 6.4 amd64':
      ensure           => present,
      name             => 'sahara-0.3-hdp-1.3-centos-6.4-amd64',
      is_public        => 'yes',
      container_format => 'bare',
      disk_format      => 'qcow2',
      source           => 'http://public-repo-1.hortonworks.com/savanna/images/centos-6_4-64-hdp-1.3.qcow2',
      require          => [Service['glance-api'], Service['keystone']],
    }
  }

}
