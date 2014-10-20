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
# == Define: profile::openstack::swift::proxy_server_pipeline_includer
#
# Includes required puppet classes for Swift proxy-server pipeline
#
# === Parameters
# [name]
#   The name of a class to include from swift::proxy namespace.
#   May be an array, for example proxy_pipeline parameter from
#   profile::openstack::swift::controller class
#
# [keystone_endpoint_ip]
#   IP of the internal keystone API endpoint
#
# [service_username]
#   The username used by swift service
#
# [service_password]
#   The password of the user used by swift service
#
# === Examples
# TODO
#
# === Authors
#
# Piotr Misiak <pmisiak@mirantis.com>
#
# === Copyright
#
# Copyright 2014 AT&T Foundry, unless otherwise noted.
define profile::openstack::swift::proxy_server_pipeline_includer ($keystone_endpoint_ip, $service_username, $service_password, $operator_roles) {
  case $name {
    'proxy-server': {}
    's3token': {
      class { 'swift::proxy::s3token':
        auth_host => $keystone_endpoint_ip,
      }
    }
    'authtoken': {
      class { 'swift::proxy::authtoken':
        admin_user          => $service_username,
        admin_password      => $service_password,
        auth_host           => $keystone_endpoint_ip,
      }
    }
    'keystone': {
      class { 'swift::proxy::keystone':
        operator_roles => $operator_roles
      }
    }
    default: { include "swift::proxy::${name}" }
  }
}

