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
# == Class: profile::openstack::compute
#
# Configures compute node.
#
# === Parameters
# TODO
#
# === Examples
# TODO
#
# === Authors
#
# James Kyle <james@jameskyle.org>
# Ari Saha <as754m@att.com>
# Paul McGoldrick <tac.pmcgoldrick@gmail.com>
# Kamil Swiatkowski <kswiatkowski@mirantis.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.
class profile::openstack::compute (
  #cloud networks
  $mgmt_interface                = undef,
  $mgmt_ctrl_ip                  = undef,
  $pub_interface                 = undef,
  $pub_ctrl_ip                   = undef,
  $priv_interface                = undef,

  # Required Nova
  $nova_user_password            = undef,
  # Required Rabbit
  $rabbit_password               = undef,
  # DB
  $nova_db_password              = undef,
  # Nova Database
  $nova_db_user                  = undef,
  $nova_db_name                  = 'nova',
  # Network
  $public_interface              = undef,
  $private_interface             = undef,
  $fixed_range                   = undef,
  $network_manager               = undef,
  $network_config                = {},
  $multi_host                    = false,
  $enabled_apis                  = 'ec2,osapi_compute,metadata',
  # Neutron
  $neutron                       = true,
  $neutron_user_password         = undef,
  $neutron_admin_tenant_name     = 'services',
  $neutron_admin_user            = undef,
  $enable_ovs_agent              = true,
  $enable_l3_agent               = true,
  $enable_dhcp_agent             = true,
  $neutron_auth_url              = undef,
  $neutron_firewall_driver       = 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
  # Nova
  $nova_admin_tenant_name        = 'services',
  $nova_admin_user               = undef,
  $purge_nova_config             = false,
  $libvirt_vif_driver            = undef,
  $nova_blkdev                   = undef,
  # Rabbit
  $rabbit_user                   = 'openstack',
  $rabbit_virtual_host           = '/',
  # Glance
  $glance_api_servers            = false,
  # Virtualization
  $libvirt_type                  = 'kvm',
  # VNC
  $vnc_enabled                   = true,
  $vncproxy_host                 = undef,
  $vncserver_listen              = false,
  $vncserver_proxyclient_address = undef,

  # cinder / volumes
  $cinder                        = false,
  $manage_volumes                = true,
  $cinder_volume_driver          = 'iscsi',
  $cinder_db_password            = undef,
  $cinder_db_user                = undef,
  $cinder_db_name                = 'cinder',
  $volume_group                  = 'cinder-volumes',
  $setup_test_volume             = false,
  $cinder_rbd_user               = 'volumes',
  $cinder_rbd_pool               = 'volumes',
  $cinder_rbd_secret_uuid        = false,
  # General
  $migration_support             = true,
  $verbose                       = 'True',
  $swift                         = true,
) {

  include sudo
  include profile::openstack::setup
  include profile::lvm::filter
  include profile::apparmor::libvirt

  $mgmt_local_ip = inline_template(
    "<%= scope.lookupvar('ipaddress_${mgmt_interface}') %>"
  )
  $mgmt_local_netmask = inline_template(
    "<%= scope.lookupvar('netmask_${mgmt_interface}') %>"
  )

  # public interface does not exist on compute node in current setup
  #$pub_local_ip = inline_template(
  #  "<%= scope.lookupvar('ipaddress_${pub_interface}') %>"
  #)
  #$pub_local_netmask = inline_template(
  #  "<%= scope.lookupvar('netmask_${pub_interface}') %>"
  #)

  $priv_local_ip = inline_template(
    "<%= scope.lookupvar('ipaddress_${priv_interface}') %>"
  )
  $priv_local_netmask = inline_template(
    "<%= scope.lookupvar('netmask_${priv_interface}') %>"
  )

  if ( $nova_blkdev != undef ) {
    exec { "fstab ${nova_blkdev}":
      command => "echo '${nova_blkdev} /var/lib/nova/instances  ext4  defaults  0 2' >> /etc/fstab",
      unless  => "grep  ${nova_blkdev} /etc/fstab",
      path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
      before  => Class['::openstack::compute'],
      notify  => Exec["mkfs.ext4 ${nova_blkdev}"],
    }
    exec { "mkfs.ext4 ${nova_blkdev}":
      command     => "mkfs.ext4 ${nova_blkdev}",
      path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
      before      => Class['::openstack::compute'],
      refreshonly => true,
      notify      => Exec["mount ${nova_blkdev}"],
    }
    exec { "mount ${nova_blkdev}":
      command     => 'mkdir -p /var/lib/nova/instances && mount /var/lib/nova/instances',
      path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
      before      => Class['::openstack::compute'],
      refreshonly => true,
    }
  }

  package { 'sysfsutils':
    ensure => installed
  }

  require_param($nova_user_password, '$nova_user_password')
  require_param($rabbit_password, '$rabbit_password')
  require_param($nova_db_password, '$nova_db_password')
  require_param($nova_db_user, '$nova_db_user')
  require_param($nova_admin_user, '$nova_admin_user')

  if $cinder {
    require_param($cinder_db_user, '$cinder_db_user')
    require_param($cinder_db_password, '$cinder_db_password')
  }

  if $neutron {
    require_param($neutron_user_password, '$neutron_user_password')
    require_param($neutron_admin_user, '$neutron_admin_user')

    $neutron_auth_url_real = get_real($neutron_auth_url,
    "http://${mgmt_ctrl_ip}:35357/v2.0"
    )

    $network_manager_real = get_real($network_manager,
      'nova.network.neutron.manager.NeutronManager'
    )

    $neutron_firewall_driver_real = get_real($neutron_firewall_driver,
      'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver'
    )

    sudo::conf {'neutron':
      content => 'neutron ALL=(root) NOPASSWD: /usr/bin/neutron-rootwrap'
    }
  }

  $libvirt_vif_driver_real = get_real($libvirt_vif_driver,
    'nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver'
  )

  $glance_api_servers_real = get_real($glance_api_servers,
    "${mgmt_ctrl_ip}:9292"
  )

  #we have to use QEMU on virtual machines
  if str2bool($::is_virtual) == true {
    $real_libvirt_type = 'qemu'
  } else {
    $real_libvirt_type = $libvirt_type
  }

  sudo::conf {'nova':
    content  => 'nova ALL=(ALL) NOPASSWD: ALL'
  }

  sudo::conf {'cinder':
    content  => 'cinder ALL=(ALL) NOPASSWD: ALL'
  }

  nova_config { 'DEFAULT/running_deleted_instance_action': value => 'reap' }
  cinder_config { 'DEFAULT/glance_host': value => $mgmt_ctrl_ip }
  #required by ceilometer:
  cinder_config { 'DEFAULT/volume_usage_audit': value => 'True' }
  cinder_config { 'DEFAULT/volume_usage_audit_period': value => 'hour' }
  cinder_config { 'DEFAULT/notification_driver': value => 'cinder.openstack.common.notifier.rpc_notifier' }

  class {'::openstack::compute':
    internal_address        => $mgmt_local_ip,
    cinder_db_password      => $cinder_db_password,
    db_host                 => $mgmt_ctrl_ip,
    fixed_range             => $fixed_range,
    glance_api_servers      => $glance_api_servers_real,
    keystone_host           => $mgmt_ctrl_ip,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    neutron                 => $neutron,
    neutron_auth_url        => $neutron_auth_url_real,
    neutron_host            => $mgmt_ctrl_ip,
    neutron_user_password   => $neutron_user_password,
    neutron_firewall_driver => $neutron_firewall_driver_real,
    rabbit_host             => $mgmt_ctrl_ip,
    rabbit_password         => $rabbit_password,
    vncproxy_host           => $vncproxy_host,
    vncserver_listen        => $vncserver_listen,
    libvirt_vif_driver      => $libvirt_vif_driver_real,
    network_manager         => $network_manager_real,
    ovs_local_ip            => $priv_local_ip,
    iscsi_ip_address        => $priv_local_ip,
    migration_support       => $migration_support,
    libvirt_type            => $real_libvirt_type,
  }

  # Initialize users for the base role
  Profile::Users::Managed<| tag == openstack  |>

  if str2bool($swift) {
    include profile::openstack::swift::storage
    Class['profile::openstack::firewall']
      -> Class['profile::openstack::swift::storage']
  }
}
