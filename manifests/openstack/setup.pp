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
# == Class: profile::openstack::setup
#
# Adds openstack repository, installs packages.
#
# === Authors
#
# James Kyle <james@jameskyle.org>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.
class profile::openstack::setup {
  package { 'ebtables': ensure => present }

  $release = 'havana'

  if ($::operatingsystem == 'Ubuntu' and
      $::lsbdistdescription =~ /^.*LTS.*$/) {
    include apt::update

    apt::source { 'ubuntu-cloud-archive':
      location          => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
      release           => "${::lsbdistcodename}-updates/${release}",
      repos             => 'main',
      required_packages => 'ubuntu-cloud-keyring',
      key               => '5EDB1B62EC4926EA',
      key_server        => 'keyserver.ubuntu.com'
    }
    apt::source { 'mysql-percona-repo':
      location          => 'http://repo.percona.com/apt/',
      release           => $::lsbdistcodename,
      repos             => 'main',
      key               => '1C4CBDCDCD2EFD2A',
      key_server        => 'keyserver.ubuntu.com',
      include_src       => false,
    }
    Exec['apt_update']
      -> Package<|
        title != 'python-software-properties' and
        title != 'ubuntu-cloud-keyring'
      |>
    Package<| title == 'ubuntu-cloud-keyring' |> -> Exec['apt_update']
  }

}
