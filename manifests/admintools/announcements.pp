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
# == Class: profile::admintools::announcements
#
# Installs Admin announcements tools
#
# === Parameters
#
# === Examples
#
# include profile::admintools::announcements
#
# === Authors
#
# Tomasz Z. Napierala <tnapierala@mirantis.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.

class profile::admintools::announcements (
  $from_email   = 'admin@example.com',
  $from_name = 'Cloud Admin',
  $from_host = $::fqdn,
  $smtp_server = 'localhost',
  $blacklist = []
) {

  if ! defined(File['/etc/occam']) {
    file { '/etc/occam':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    }
  }

  file { '/etc/occam/os_users_notify.yaml':
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('profile/admintools/announcements/os_users_notify.yaml.erb'),
    require => File['/etc/occam']
  }

  file { '/usr/bin/os_users_notify.rb':
    ensure  => present,
    mode    => '0700',
    owner   => 'root',
    group   => 'root',
    source  => 'puppet:///modules/profile/admintools/os_users_notify.rb',
    require => File['/etc/occam/os_users_notify.yaml']
  }
}