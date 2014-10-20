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
# == Define: profile::routing::rt_table
#
# Configures additional routing tables.
#
# === Parameters
#
# [*interface*]
#
# [*ipaddress*]
#
# [*netmask*]
#
# [*network*]
#
# [*gateway*]
#
# [*table_prefix*]
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
# Copyright 2014 AT&T Foundry, unless otherwise noted.
define profile::routing::rt_table (
  $interface    = undef,
  $ipaddress    = undef,
  $netmask      = undef,
  $network      = undef,
  $gateway      = undef,
  $table_prefix = 'puppet'
) {

  if $interface == undef {
    fail('interface param needs to be defined')
  }

  if $ipaddress == undef {
    fail('ipaddress param needs to be defined')
  }

  if $netmask == undef {
    fail('netmask param needs to be defined')
  }

  if $network == undef {
    fail('network param needs to be defined')
  }

  if $gateway == undef {
    $tmp = split($network,'[.]')
    $tmp1 = 0 + $tmp[3]
    $tmp2 = 1 + $tmp1
    $l_gateway = regsubst($network,'(\d+)$',"${tmp2}")
  } else {
    $l_gateway = $gateway
  }

  $table = "${table_prefix}.${$interface}"
  $rtfile = '/etc/iproute2/rt_tables'
  $tncmd = "grep ${table_prefix} ${rtfile} |cut -d' ' -f1 | sort -rn | head -n1"

  exec { "create_rt_table_${table}":
    command => "echo \"\$((`${tncmd}` + 1)) ${table}\" >> ${rtfile}",
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    unless  => [
      "grep ${table} ${rtfile}",
      "ip route show | grep default | grep ${l_gateway}",
    ],
    before  => Exec["ip_route_net_${table}"],
  }

  exec { "ip_route_net_${table}":
    command => "ip route add ${network}/${netmask} dev ${interface} src ${ipaddress} table ${table}",
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    unless  => [
      "ip route show table ${table}| grep ${interface} | grep ${ipaddress}",
      "ip route show | grep default | grep ${l_gateway}",
    ],
    before  => Exec["ip_route_gw_${table}"],
  }

  exec { "ip_route_gw_${table}":
    command => "ip route add default via ${l_gateway} table ${table}",
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    unless  => [
      "ip route show table ${table}| grep default | grep ${l_gateway}",
      "ip route show | grep default | grep ${l_gateway}",
    ],
    before  => Exec["ip_rule_${table}"],
  }

  exec { "ip_rule_${table}":
    command => "ip rule add from ${ipaddress} table ${table}",
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    unless  => [
      "ip rule show | grep ${ipaddress} | grep ${table}",
      "ip route show | grep default | grep ${l_gateway}",
    ],
  }

}

