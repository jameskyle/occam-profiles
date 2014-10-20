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
# == Define: profile::routing::rt_tables
#
# Configures additional routing tables.
#
# === Parameters
#
# NONE
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
define profile::routing::rt_tables {
  if $name != 'lo' {
    $fact_ipaddress = "ipaddress_${name}"
    $fact_netmask = "netmask_${name}"
    $fact_network = "network_${name}"
    $fact_interface_name = "interface_name_${name}"
    $ipaddress = inline_template('<%= scope.lookupvar(@fact_ipaddress) %>')
    $netmask = inline_template('<%= scope.lookupvar(@fact_netmask) %>')
    $network = inline_template('<%= scope.lookupvar(@fact_network) %>')
    $interface_name = inline_template('<%= scope.lookupvar(@fact_interface_name) %>')
    if ($ipaddress != '' and ! defined(Profile::Routing::Rt_table["routing_table_${network}"]) and $ipaddress !~ /^10\.99\./) {
      profile::routing::rt_table { "routing_table_${network}":
        interface => $interface_name,
        ipaddress => $ipaddress,
        netmask   => $netmask,
        network   => $network,
      }
    }
  }
}

