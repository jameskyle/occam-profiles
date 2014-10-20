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
# == Define: profile::openstack::flavor_add
#
# Adds flavor in OpenStack.
#
# === Parameters
# TODO
#
# === Examples
# TODO
#
# === Authors
#
# Szymon Banka <sbanka@mirantis.com>
#
# === Copyright
#
# Copyright 2014 AT&T Foundry, unless otherwise noted.

define profile::openstack::flavor_add (
  $fl_ephemeral_size,
  $fl_is_public,
  $fl_id,
  $fl_root_disk_size,
  $fl_ram,
  $fl_vcpus,
  $fl_swap,
  $fl_rxtx_factor
) {
    exec { "add_flavor_${name}":
      command  => "nova-manage flavor create ${name} ${fl_ram}\
      ${fl_vcpus} ${fl_root_disk_size} ${fl_ephemeral_size}\
      ${fl_id} ${fl_swap} ${fl_rxtx_factor} ${fl_is_public}",
      provider => 'shell',
      path     => '/usr/bin',
    }
}
