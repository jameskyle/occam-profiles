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
# == Class: profile::openstack::proxy
#
# Proxies all the openstack service endpoints.
#
# === Parameters
#
# [listen_address]
#   The address the proxy should listen on. Default: $::ipaddress
#
# [certificate]
#   The certificate to deploy with the proxy. Should be a cert + key in that
#   order.
#
# [user]
#   The user to run the proxy as. Default: haproxy
#
# [group]
#   The group to run the proxy as. Default: haproxy
#
# [verify]
#   Proxy certificate verification level. Default: 0
#
# [firewall]
#   Whether to run a firewall restricting access to all public traffic except
#   those over the proxy ports.
#
# [ssh]
#   Whether to open the ssh port on the public interface. Primarily for
#   debugging. Default: false
#
# [ppa]
#   PPA to add. Required for ssl enabled proxy package
#   Default: ppa:vbernat/haproxy-1.5
#
# === Examples
#
#  class { 'profile::openstack::proxy':
#    $listen_address          = $::ipaddress,
#    $redirect_http           = true,
#    $user                    = 'haproxy',
#    $group                   = 'haproxy',
#    $verify                  = '0',
#    $firewall                = true,
#    $ssh                     = false,
#    $ppa                     = 'ppa:vbernat/haproxy-1.5 ',
#  }
#
# === Authors
#
# James Kyle <james@jameskyle.org>
# Paul McGoldrick <tac.pmcgoldrick@gmail.com>
# Damian Szeluga <dszeluga@mirantis.com>
# Piotr Misiak <pmisiak@mirantis.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.
#

class profile::openstack::proxy (
  $listen_address_mgmt    = undef,
  $listen_address_pub     = undef,
  $certificate            = undef,
  $certificate_name       = 'certificate.pem',
  $user                   = 'haproxy',
  $group                  = 'haproxy',
  $verify                 = '0',
  $firewall               = undef,
  $ssh                    = false,
  $ppa                    = 'ppa:vbernat/haproxy-1.5',
  $horizon_url            = 'cloud.domain.com',
  $nova_url               = 'compute.cloud.domain.com',
  $neutron_url            = 'net.cloud.domain.com',
  $glance_url             = 'image.cloud.domain.com',
  $cinder_url             = 'vol.cloud.domain.com',
  $ec2_url                = 'ec2.cloud.domain.com',
  $keystone_url           = 'auth.cloud.domain.com',
  $savanna_url            = 'mapreduce.cloud.domain.com',
  $ceilometer_url         = 'ceilometer.cloud.domain.com',
  $swift_url              = 'swift.cloud.domain.com',
) {
  apt::ppa {$ppa: }

  sysctl::value { 'net.ipv4.ip_nonlocal_bind':
    value  => '1',
    before => Class['haproxy']
  }

  class {'haproxy':
    enable           => true,
    global_options   => {
      'maxconn' => '16384',
      'nbproc'  => '1',
      'daemon'  => '',
      'log'     => '/dev/log local0',
      'stats'   => 'socket /var/lib/haproxy/stats',
    },
    defaults_options => {
      'log'     => 'global',
      'maxconn' => '8000',
      'option'  => ['httplog', 'forwardfor', 'forceclose'],
      'mode'    => 'http',
      'balance' => 'roundrobin',
      'timeout' => [
        'http-request 10s',
        'queue 1m',
        'connect 10s',
        'client 1m',
        'server 1m',
      ],
    },
  }
  $is_horizon         = "is_horizon hdr_end(host) -i ${horizon_url}"
  $is_novnc           = 'is_novnc dst_port 6080'
  $is_redirect        = 'is_redirect dst_port 80'
  $is_nova            = "is_nova hdr_end(host) -i ${nova_url} || dst_port 8774 "
  $is_neutron         = "is_neutron     hdr_end(host) -i ${neutron_url} || dst_port 9696"
  $is_glance          = "is_glance   hdr_end(host) -i ${glance_url} || dst_port 9292"
  $is_cinder          = "is_cinder     hdr_end(host) -i ${cinder_url} || dst_port 8776"
  $is_savanna         = "is_savanna    hdr_end(host) -i ${savanna_url} || dst_port 8386"
  $is_ec2             = "is_ec2     hdr_end(host) -i ${ec2_url} || dst_port 8773"
  $is_keystone        = "is_keystone    hdr_end(host) -i ${keystone_url} || dst_port 5000"
  $is_keystone_admin  = "is_keystone_admin    dst_port 35357"
  $is_ceilometer      = "is_ceilometer hdr_end(host) -i ${ceilometer_url} || dst_port 8777"
  $is_swift           = "is_swift hdr_end(host) -i ${swift_url} || dst_port 8080"
  $is_rabbit          = "is_rabbit  dst_port 5672"
  $is_metadata        = "is_metadata  dst_port 8775"
  $acls               = [
     $is_horizon,
     $is_novnc,
     $is_redirect,
     $is_nova,
     $is_neutron,
     $is_glance,
     $is_cinder,
     $is_ec2,
     $is_keystone,
     $is_keystone_admin,
     $is_savanna,
     $is_ceilometer,
     $is_swift,
     $is_rabbit,
     $is_metadata,
  ]

  $backends           = [
    'nova if is_nova',
    'neutron if is_neutron',
    'glance if is_glance',
    'cinder if is_cinder',
    'ec2 if is_ec2',
    'keystone if is_keystone',
    'keystone_admin if is_keystone_admin',
    'horizon if is_horizon',
    'novnc if is_novnc',
    'savanna if is_savanna',
    'ceilometer if is_ceilometer',
    'swift if is_swift',
    'rabbit if is_rabbit',
    'metadata if is_metadata',
  ]

  haproxy::frontend {'openstack-public':
    ipaddress           => [],
    ports               => [],
    options             => {
      'bind'            => [
        "${listen_address_pub}:80",
        "${listen_address_pub}:443  ssl crt /etc/ssl/certs/haproxy.pem",
        "${listen_address_pub}:5000 ssl crt /etc/ssl/certs/haproxy.pem",
        "${listen_address_pub}:6080 ssl crt /etc/ssl/certs/haproxy.pem",
        "${listen_address_pub}:9292 ssl crt /etc/ssl/certs/haproxy.pem",
        "${listen_address_pub}:8773 ssl crt /etc/ssl/certs/haproxy.pem",
        "${listen_address_pub}:8776 ssl crt /etc/ssl/certs/haproxy.pem",
        "${listen_address_pub}:9696 ssl crt /etc/ssl/certs/haproxy.pem",
        "${listen_address_pub}:8774 ssl crt /etc/ssl/certs/haproxy.pem",
        "${listen_address_pub}:8386 ssl crt /etc/ssl/certs/haproxy.pem",
        "${listen_address_pub}:8777 ssl crt /etc/ssl/certs/haproxy.pem",
        "${listen_address_pub}:8080 ssl crt /etc/ssl/certs/haproxy.pem",
      ],
      'acl'             => $acls,
      'use_backend'     => $backends,
      'redirect'        => 'scheme https if is_redirect',
      'http-request'    => [
        'add-header X-Forwarded-Proto https',
        'add-header X-Forwarded-Protocol https',
      ],
    },
  }

  haproxy::frontend {'openstack-management':
    ipaddress           => [],
    ports               => [],
    options             => {
      'bind'            => [
        "${listen_address_mgmt}:80",
        "${listen_address_mgmt}:5000",
        "${listen_address_mgmt}:35357",
        "${listen_address_mgmt}:6080",
        "${listen_address_mgmt}:9292",
        "${listen_address_mgmt}:8773",
        "${listen_address_mgmt}:8776",
        "${listen_address_mgmt}:9696",
        "${listen_address_mgmt}:8774",
        "${listen_address_mgmt}:8386",
        "${listen_address_mgmt}:8777",
        "${listen_address_mgmt}:8080",
        "${listen_address_mgmt}:5672",
        "${listen_address_mgmt}:8775",
      ],
      'acl'             => $acls,
      'use_backend'     => $backends,
    },
  }

  haproxy::backend {'horizon':
    options => {
      'option'  => [],
    },
  }

  haproxy::backend {'novnc':
    options => {
      'option'  => [],
    },
  }

  haproxy::backend {'keystone':
    options => {
      'option'  => [],
    },
  }
  haproxy::backend {'keystone_admin':
    options => {
      'option'  => [],
    },
  }
  haproxy::backend {'glance':
    options => {
      'option'  => [],
    },
  }
  haproxy::backend {'ec2':
    options => {
      'option'  => [],
    },
  }
  haproxy::backend {'cinder':
    options => {
      'option'  => [],
    },
  }
  haproxy::backend {'neutron':
    options => {
      'option'  => [],
    },
  }
  haproxy::backend {'nova':
    options => {
      'option'  => [],
    },
  }
  haproxy::backend {'savanna':
    options => {
      'option'  => [],
    },
  }
  haproxy::backend {'ceilometer':
    options => {
      'option'  => [],
    },
  }
  haproxy::backend {'swift':
    options => {
      'option'  => [],
    },
  }
  haproxy::backend {'rabbit':
    options => {
      'option'  => [],
    },
  }
  haproxy::backend {'metadata':
    options => {
      'option'  => [],
    },
  }

  if $firewall {
    firewall { '100 allow service ports':
      port        => [80,443,6080,9292,5000,8386,8773,8774,8776,9696,8080],
      proto       => 'tcp',
      destination => $listen_address_pub,
      action      => 'accept',
    }->
    firewall { '200 deny by default on public':
        proto       => 'all',
        destination => $listen_address_pub,
        action      => 'drop',
    }

    if $ssh {
      firewall {'200 allow public ssh access':
        port        => 22,
        proto       => tcp,
        destination => $listen_address_pub,
      }
    }
  }

  if $certificate == undef {
    file {'/etc/ssl/certs/haproxy.pem':
      mode    => '0440',
      owner   => 'root',
      group   => 'root',
      source  => "puppet:///modules/profile/ssl/${certificate_name}",
      before  => Class['haproxy'],
    }
  } else {
    file {'/etc/ssl/certs/haproxy.pem':
      mode    => '0440',
      owner   => 'root',
      group   => 'root',
      content => $certificate,
      before  => Class['haproxy'],
    }
  }
}
