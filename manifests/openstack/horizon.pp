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
# == Class: profile::openstack::horizon
#
# Proxies all the openstack service endpoints.
#
# === Parameters
#
#  [*secret_key*]
#    (required) Secret key. This is used by Django to provide cryptographic
#    signing, and should be set to a unique, unpredictable value.
#
#  [*memcached_listen_ip*]
#    (optional) Memcached IP address. Defaults to '127.0.0.1'.
#
#  [*memcached_server_port*]
#    (optional) Memcached port. Defaults to '11211'.
#
#  [*horizon_app_links*]
#    (optional) Array of arrays that can be used to add call-out links
#    to the dashboard for other apps. There is no specific requirement
#    for these apps to be for monitoring, that's just the defacto purpose.
#    Each app is defined in two parts, the display name, and
#    the URIDefaults to false. Defaults to false. (no app links)
#
#  [*keystone_host*]
#    (optional) IP address of the Keystone service. Defaults to '127.0.0.1'.
#
#  [*keystone_scheme*]
#    (optional) Scheme of the Keystone service. Defaults to 'http'.
#
#  [*keystone_port*]
#    (optional) Port on which Keystone listen.
#
#  [*keystone_default_role*]
#    (optional) Default Keystone role for new users. Defaults to '_member_'.
#
#  [*django_debug*]
#    (optional) Enable or disable Django debugging. Defaults to 'False'.
#
#  [*api_result_limit*]
#    (optional) Maximum number of Swift containers/objects to display
#    on a single page. Defaults to 1000.
#
# === Examples
#
#  include profile::openstack::horizon
#
# === Authors
#
# James Kyle <james@jameskyle.org>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.
#


class profile::openstack::horizon (
  $secret_key              = 'dummy_secret_key',
  $service_interface       = 'lo',
  $configure_memcached     = true,
  $memcached_listen_ip     = '127.0.0.1',
  $memcached_server_port   = '11211',
  $horizon_app_links       = undef,
  $keystone_host           = '127.0.0.1',
  $keystone_scheme         = 'http',
  $keystone_port           = '5000',
  $keystone_default_role   = '_member_',
  $django_debug            = 'False',
  $api_result_limit        = 1000,
  $allowed_hosts           = $::fqdn,
  $local_settings_template = 'profile/horizon/local_settings.py.erb',
  $ssl_no_verify           = False,
  $ssl_proxy               = True,
) {

  $bind_address = inline_template(
    "<%= scope.lookupvar('ipaddress_${service_interface}') %>"
  )

  class { 'memcached':
    listen_ip => $memcached_listen_ip,
    tcp_port  => $memcached_server_port,
    udp_port  => $memcached_server_port,
  }

  class { '::horizon':
    cache_server_ip         => $memcached_listen_ip,
    cache_server_port       => $memcached_server_port,
    secret_key              => $secret_key,
    horizon_app_links       => $horizon_app_links,
    keystone_url            => "${keystone_scheme}://${keystone_host}:${keystone_port}/v2.0",
    keystone_default_role   => $keystone_default_role,
    django_debug            => $django_debug,
    api_result_limit        => $api_result_limit,
    bind_address            => $bind_address,
    local_settings_template => $local_settings_template,
    fqdn                    => $allowed_hosts,
  }

  if str2bool($::selinux) {
    selboolean{'httpd_can_network_connect':
      value      => on,
      persistent => true,
    }
  }
}

