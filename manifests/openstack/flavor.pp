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
# == Class: profile::openstack::flavor
#
# Removes and adds flavors.
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

class profile::openstack::flavor {
  if $::puppet_state {

    flavor_delete { 'm1.tiny':}
    flavor_delete { 'm1.small':}
    flavor_delete { 'm1.medium':}
    flavor_delete { 'm1.large':}
    flavor_delete { 'm1.xlarge':}

    flavor_add { 'm1.tiny':
      fl_ephemeral_size  => '2',
      fl_is_public       => '1',
      fl_id              => '1',
      fl_root_disk_size  => '1',
      fl_ram             => '512',
      fl_vcpus           => '1',
      fl_swap            => '0',
      fl_rxtx_factor     => '1',
      require            => Flavor_delete['m1.tiny'],
    }

    flavor_add { 'm1.small':
      fl_ephemeral_size  => '2',
      fl_is_public       => '1',
      fl_id              => '2',
      fl_root_disk_size  => '20',
      fl_ram             => '2048',
      fl_vcpus           => '1',
      fl_swap            => '0',
      fl_rxtx_factor     => '1',
      require            => Flavor_delete['m1.small'],
    }

    flavor_add { 'm1.medium':
      fl_ephemeral_size  => '2',
      fl_is_public       => '1',
      fl_id              => '3',
      fl_root_disk_size  => '40',
      fl_ram             => '4096',
      fl_vcpus           => '2',
      fl_swap            => '0',
      fl_rxtx_factor     => '1',
      require            => Flavor_delete['m1.medium'],
    }

    flavor_add { 'm1.large':
      fl_ephemeral_size  => '2',
      fl_is_public       => '1',
      fl_id              => '4',
      fl_root_disk_size  => '80',
      fl_ram             => '8192',
      fl_vcpus           => '4',
      fl_swap            => '0',
      fl_rxtx_factor     => '1',
      require            => Flavor_delete['m1.large'],
    }

    flavor_add { 'm1.xlarge':
      fl_ephemeral_size  => '2',
      fl_is_public       => '1',
      fl_id              => '5',
      fl_root_disk_size  => '160',
      fl_ram             => '16384',
      fl_vcpus           => '8',
      fl_swap            => '0',
      fl_rxtx_factor     => '1',
      require            => Flavor_delete['m1.xlarge'],
    }
  }
}
