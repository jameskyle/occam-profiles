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
# == Class: profile::lvm::filter
#
# LVM device filter setting.
#
# === Parameters
# [filter]
#   LVM filter definition. Defaults to iscsi devices
#
# === Authors
#
# Kamil Swiatkowski <kswiatkowski@mirantis.com>
#
# === Copyright
#
# Copyright 2014 AT&T Foundry, unless otherwise noted.
class profile::lvm::filter (
  $filter = '[ "r|/dev/disk/by-path/ip-.*|" ]'
) {

  $filteresc1 = regsubst( $filter, '/', '\/', 'G')
  $filteresc2 = regsubst( $filteresc1, '\[', '\\[', 'G')
  $filteresc = regsubst( $filteresc2, '\]', '\\]', 'G')

  exec { 'set lvm filter':
    command => "sed -i -e 's/    filter = .*/    filter = ${filteresc}/' /etc/lvm/lvm.conf",
    unless  => "grep '    filter = ${filteresc}' /etc/lvm/lvm.conf",
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    require => Package['lvm2'],
  }

}
