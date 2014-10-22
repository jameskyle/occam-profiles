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
# == Class: profile::puppet::master
#
# Configures puppet master.
#
# === Parameters
# [storeconfigs]
#   enable/disable storeconfigs
#
# [puppet_root]
#   path to puppet root
#
# [autosign]
#   enable/disable autosign
#
# [environment]
#   what environment to use
#
# === Examples
# class {'profile::puppet::master:
#   storeconfigs      = true,
#   puppet_root       = '/var/puppet',
#   autosign          = true,
#   environment       = 'production',
# }
#
# === Authors
#
# James Kyle <james@jameskyle.org>
# Ari Saha <as754m@att.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.
class profile::puppet::master (
  $storeconfigs      = true,
  $autosign          = true,
  $environment       = 'production',
) {

  include profile::hiera::config

  class { 'puppetdb':
    ssl_listen_address => '0.0.0.0',
    java_args          => { '-Xmx' => '4g' }
  }

  class {'::puppet::master':
    storeconfigs => true,
    environments => 'directory',
    autosign     => '$confdir/autosign.conf { mode = 664 }',
    reports      => 'store,foreman,puppetdb',
  }

  # we want to  ensure puppet master has certain dns entries...it's a
  # chicken and egg situation with a dns server since we want to manage that
  # with puppet

  # set master to current fqdn
  Ini_setting {
    path    => '/etc/puppet/puppet.conf',
    require => Class['::puppet::master'],
    notify  => Service['httpd']
  }

  ini_setting {'mainserversetting':
    ensure  => present,
    section => 'main',
    setting => 'server',
    value   => $::fqdn
  }

  ini_setting {'mainlogsetting':
    ensure  => present,
    section => 'main',
    setting => 'logdir',
    value   => '/var/log/puppet',
  }

 ini_setting {'mainrundirsetting':
    ensure  => present,
    section => 'main',
    setting => 'rundir',
    value   => '/var/run/puppet',
  }

  ini_setting {'mainssldirsetting':
    ensure  => present,
    section => 'main',
    setting => 'ssldir',
    value   => '$vardir/ssl',
  }

  ini_setting {'mainprivatekeydirsetting':
    ensure  => present,
    section => 'main',
    setting => 'privatekeydir',
    value   => '$ssldir/private_keys { group = service }',
  }


  ini_setting {'mainhostprivkeysetting':
    ensure  => present,
    section => 'main',
    setting => 'hostprivkey',
    value   => '$privatekeydir/$certname.pem { mode = 640 }',
  }

  ini_setting {'mainshowdiffsetting':
    ensure  => present,
    section => 'main',
    setting => 'showdiff',
    value   => false,
  }


  ini_setting {'mainhiera_configsetting':
    ensure  => present,
    section => 'main',
    setting => 'hiera_config',
    value   => '$confdir/hiera.yaml',
  }

  ini_setting {'masternodeterminussetting':
    ensure  => present,
    section => 'master',
    setting => 'node_terminus',
    value   => 'exec'
  }

  ini_setting {'masterexternalnodessetting':
    ensure  => present,
    section => 'master',
    setting => 'external_nodes',
    value   => '/etc/puppet/node.rb',
  }


  ini_setting {'mastercasetting':
    ensure  => present,
    section => 'master',
    setting => 'ca',
    value   => true,
  }

  ini_setting {'masterssldirsetting':
    ensure  => present,
    section => 'master',
    setting => 'ssldir',
    value   => '/var/lib/puppet/ssl',
  }

  ini_setting {'mastercertnamesetting':
    ensure  => present,
    section => 'master',
    setting => 'certname',
    value   => $::fqdn,
  }

  ini_setting {'masterstrict_variablesetting':
    ensure  => present,
    section => 'master',
    setting => 'strict_variables',
    value   => false,
  }

  ini_setting {'masterbasemodulepathsetting':
    ensure  => present,
    section => 'master',
    setting => 'basemodulepath',
    value   => '/etc/puppet/environments/common:/etc/puppet/modules:/usr/share/puppet/modules',
  }

  ini_setting {'masterstoreconfigs_backendsetting':
    ensure  => present,
    section => 'master',
    setting => 'storeconfigs_backend',
    value   => 'puppetdb',
  }
}
