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
# Configures controller node.
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
class profile::openstack::controller (
  #cloud networks
  $mgmt_interface         = undef,
  $mgmt_ctrl_ip           = undef,
  $pub_interface          = undef,
  $pub_ctrl_ip            = undef,
  $priv_interface         = undef,
  # Required Network
  $public_address         = undef,
  $bind_address           = '0.0.0.0',
  $public_protocol        = 'http',
  $admin_email            = 'foo@bar.com',
  # required password
  $admin_password         = undef,
  $rabbit_password        = undef,
  $keystone_db_password   = undef,
  $keystone_admin_token   = undef,
  $glance_db_password     = undef,
  $glance_user_password   = undef,
  $nova_db_password       = undef,
  $nova_user_password     = undef,
  $secret_key             = undef,
  $mysql_root_password    = undef,
  # cinder and neutron password are not required b/c they are
  # optional. Not sure what to do about this.
  $neutron_user_password   = undef,
  $neutron_db_password     = undef,
  $neutron_core_plugin     = 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2',
  $allow_overlapping_ips   = undef,
  $cinder_user_password    = undef,
  $cinder_db_password      = undef,
  # Database
  $mysqld_settings         = {},
  $db_host                 = '127.0.0.1',
  $db_type                 = 'mysql',
  $mysql_account_security  = true,
  $sql_idle_timeout        = undef,
  $allowed_hosts           = undef,
  # Keystone
  $keystone_db_user        = undef,
  $keystone_db_dbname      = 'keystone',
  $keystone_admin_tenant   = 'admin',
  $region                  = 'RegionOne',
  $keystone_token_format   = 'UUID',
  # Glance
  $glance_db_user          = undef,
  $glance_db_dbname        = 'glance',
  $glance_backend          = 'file',
  $glance_blkdev           = undef,
  # Nova
  $nova_admin_tenant_name  = 'services',
  $nova_admin_user         = undef,
  $nova_db_user            = undef,
  $nova_db_dbname          = 'nova',
  $purge_nova_config       = false,
  $enabled_apis            = 'ec2,osapi_compute,metadata',
  # Nova Networking
  $public_interface        = undef,
  $private_interface       = undef,
  $network_manager         = 'nova.network.neutron.manager.NeutronManager',
  $fixed_range             = undef,
  $floating_range          = undef,
  $create_networks         = true,
  $num_networks            = 1,
  $multi_host              = false,
  $auto_assign_floating_ip = false,
  $network_config          = undef,
  # Rabbit
  $rabbit_hosts            = false,
  $rabbit_cluster_nodes    = false,
  $rabbit_user             = 'openstack',
  $rabbit_virtual_host     = '/',
  # VNC
  $vnc_enabled             = true,
  $vncproxy_host           = true,
  # General
  $debug                   = 'True',
  $verbose                 = 'True',
  # cinder
  # if the cinder management components should be installed
  $cinder                  = true,
  $cinder_db_user          = undef,
  $cinder_db_dbname        = 'cinder',
  $cinder_quota_volumes    = undef,
  $cinder_quota_snapshots  = undef,
  $cinder_quota_gigabytes  = undef,
  $disable_quotas          = true,
  # Neutron
  $neutron                 = true,
  $physical_network        = 'default',
  $tenant_network_type     = 'gre',
  $ovs_enable_tunneling    = true,
  $network_vlan_ranges     = undef,
  $bridge_interface        = undef,
  $external_bridge_name    = 'br-ex',
  $bridge_uplinks          = undef,
  $bridge_mappings         = undef,
  $enable_ovs_agent        = true,
  $enable_dhcp_agent       = true,
  $enable_l3_agent         = true,
  $enable_metadata_agent   = true,
  $metadata_shared_secret  = false,
  $neutron_firewall_driver = 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
  $neutron_db_user         = undef,
  $neutron_db_name         = 'neutron',
  $enable_neutron_server   = true,
  $instance_mtu            = '1500',
  $neutron_external_dns    = '8.8.8.8',
  $controllers_ip          = undef,
  $controllers_name        = undef,
  $mysqls                  = undef,
  $galera_synced           = [],
  $ha                      = false,
  $real_db_host            = undef,
  $swift                   = true,
){

  include sudo
  include interfaces

  require_param($mgmt_interface, '$mgmt_interface')
  require_param($mgmt_ctrl_ip, '$mgmt_ctrl_ip')
  require_param($pub_interface, '$pub_interface')
  require_param($pub_ctrl_ip, '$pub_ctrl_ip')
  require_param($priv_interface, '$priv_interface')

  $mgmt_local_ip = inline_template(
    "<%= scope.lookupvar('ipaddress_${mgmt_interface}') %>"
  )
  $mgmt_local_netmask = inline_template(
    "<%= scope.lookupvar('netmask_${mgmt_interface}') %>"
  )

  $pub_local_ip = inline_template(
    "<%= scope.lookupvar('ipaddress_${pub_interface}') %>"
  )
  $pub_local_netmask = inline_template(
    "<%= scope.lookupvar('netmask_${pub_interface}') %>"
  )

  $priv_local_ip = inline_template(
    "<%= scope.lookupvar('ipaddress_${priv_interface}') %>"
  )
  $priv_local_netmask = inline_template(
    "<%= scope.lookupvar('netmask_${priv_interface}') %>"
  )

  $controllers_ip_sorted = sort($controllers_ip)
  $controllers_name_sorted = sort($controllers_name)

  $controller_count = size($controllers_ip_sorted)
  $mysql_count = size($mysqls)
  $config_ha = str2bool($ha)

  if ($config_ha) {

    $theone = galera_master($controllers_ip_sorted)
    $thenext = galera_nextserver($::ipaddress_eth0, $controllers_ip_sorted)
    $theothers = galera_neighbors($::ipaddress_eth0, $controllers_ip_sorted)

    if ( $thenext and member($galera_synced, $thenext) ) {
      $thenext_synced = $thenext
    } else {
      $thenext_synced = ''
    }
  }

  if (($config_ha == true) and ($controller_count >= 3)) {

    if (($theone != $::ipaddress_eth0) and ($thenext_synced == '')) {
      $config_run = false
    } else {
      $config_run = true
    }

  } elsif  ($config_ha == false) {
    $config_run = true
  } else {
    $config_run = false
  }

  if ($config_run) {

    if ( $glance_blkdev != undef ) {
      exec { "fstab ${glance_blkdev}":
        command => "echo '${glance_blkdev} /var/lib/glance  ext4  defaults  0 2' >> /etc/fstab",
        unless  => "grep  ${glance_blkdev} /etc/fstab",
        path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
        before  => Class['::openstack::controller'],
        notify  => Exec["mkfs.ext4 ${glance_blkdev}"],
      }
      exec { "mkfs.ext4 ${glance_blkdev}":
        command     => "mkfs.ext4 ${glance_blkdev}",
        path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
        before      => Class['::openstack::controller'],
        refreshonly => true,
        notify      => Exec["mount ${glance_blkdev}"],
      }
      exec { "mount ${glance_blkdev}":
        command     => 'mkdir -p /var/lib/glance && mount /var/lib/glance',
        path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
        before      => Class['::openstack::controller'],
        refreshonly => true,
      }
    }

    # generic receive offload (gro) need to be switched off
    # on bridge interface when GRE is in use
    exec { "switch off gro on ${bridge_interface}":
      command => "ethtool -K ${bridge_interface} gro off",
      unless  => "ethtool -k ${bridge_interface} | grep 'generic-receive-offload: off'",
      path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
      require => Package['ethtool'],
    }

    if ($config_ha) {
      #external bridge need to be set up WITHOUT GATEWAY!
      network::interface{$external_bridge_name:
          family  => 'inet',
          method  => 'manual',
          auto    => '1',
          post_up => ['ifconfig $IFACE up'],
          pre_down => ['ifconfig $IFACE down'],
      }
      #percona dirty hack
      exec {'fake mysql config':
        command => 'mkdir /etc/mysql; echo "[mysqld]\npid-file = /var/run/mysqld/mysqld.pid\nquery_cache_size = 0\ninnodb_log_file_size = 50331648" > /etc/mysql/my.cnf',
        path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
        creates => '/etc/mysql/my.cnf',
        before  => Service['mysqld'],
      }
      #rabbit host(s)
      $ha_rabbit_hosts = $controllers_name_sorted
      $ha_rabbit_cluster_nodes = $controllers_name_sorted

    } else {
      #mgmt virtual ip for ctrl
      if ($mgmt_local_ip != $mgmt_ctrl_ip) {
        network::interface{"${mgmt_interface}:0":
            family  => 'inet',
            method  => 'static',
            ipaddr  => "${mgmt_ctrl_ip}",
            netmask => "${mgmt_local_netmask}",
        }
      }

      #external bridge need to be set up WITHOUT GATEWAY!
      $bridge_config = hiera($external_bridge_name)
      network::interface {$external_bridge_name:
          family  => $bridge_config['family'],
          method  => 'static',
          ipaddr  => "${bridge_config['address']}",
          netmask => "${bridge_config['netmask']}",
      }

      #rabbit host(s)
      $ha_rabbit_hosts = false
      $ha_rabbit_cluster_nodes = false
    }

    Class['::openstack::controller'] -> Interfaces::Iface[$external_bridge_name]

    require_param($public_address, '$public_address')
    require_param($admin_password, '$admin_password')
    require_param($rabbit_password, '$rabbit_password')
    require_param($keystone_db_password, '$keystone_db_password')
    require_param($keystone_admin_token, '$keystone_admin_token')
    require_param($glance_db_password, '$glance_db_password')
    require_param($glance_user_password, '$glance_user_password')
    require_param($nova_db_password, '$nova_db_password')
    require_param($nova_user_password, '$nova_user_password')
    require_param($secret_key, '$secret_key')
    require_param($mysql_root_password, '$mysql_root_password')
    require_param($keystone_db_user, '$keystone_db_user')
    require_param($glance_db_user, '$glance_db_user')
    require_param($nova_admin_user, '$nova_admin_user')
    require_param($nova_db_user, '$nova_db_user')
    require_param($metadata_shared_secret, '$metadata_shared_secret')

    if $cinder {
      require_param($cinder_db_user, '$cinder_db_user')
      require_param($cinder_user_password, '$cinder_user_password')
      require_param($cinder_db_password, '$cinder_db_password')
    }

    if $neutron {
      require_param($neutron_db_user, '$neutron_db_user')
      require_param($neutron_user_password, '$neutron_user_password')
      require_param($neutron_db_password, '$neutron_db_password')

      $neutron_firewall_driver_real = get_real($neutron_firewall_driver,
        'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver'
      )

      # FIXME: not being passed through??
      $neutron_core_plugin_real = get_real($neutron_core_plugin,
        'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2'
      )

      class {'neutron::quota':
        quota_network        => 20,
        quota_subnet         => 20,
        quota_router         => 20,
        quota_security_group => 20,
        require              => Class['profile::openstack::setup'],
      }

      sudo::conf {'neutron':
        content => 'neutron ALL=(root) NOPASSWD: /usr/bin/neutron-rootwrap'
      }

      class { 'profile::openstack::neutron_addons':
        instance_mtu => $instance_mtu,
        external_dns => $neutron_external_dns
      }
    }

    sudo::conf {'nova':
      content => 'nova ALL=(ALL) NOPASSWD: ALL'
    }
    sudo::conf {'cinder':
      content => 'cinder ALL=(ALL) NOPASSWD: ALL'
    }

    cinder_config { 'DEFAULT/glance_host': value => $mgmt_ctrl_ip }

    if $disable_quotas {
      cinder_config { 'DEFAULT/quota_volumes':   value => $cinder_quota_volumes }
      cinder_config { 'DEFAULT/quota_snapshots': value => $cinder_quota_snapshots }
      cinder_config { 'DEFAULT/quota_gigabytes': value => $cinder_quota_gigabytes }

      class {'nova::quota':
        quota_instances                       =>  -1,
        quota_cores                           =>  -1,
        quota_ram                             =>  -1,
        quota_volumes                         =>  -1,
        quota_gigabytes                       =>  -1,
        quota_floating_ips                    =>  -1,
        quota_metadata_items                  =>  -1,
        quota_max_injected_files              =>  -1,
        quota_max_injected_file_content_bytes =>  -1,
        quota_max_injected_file_path_bytes    =>  -1,
        quota_security_groups                 =>  -1,
        quota_security_group_rules            =>  -1,
        require                               => Class['profile::openstack::setup'],
      }
    }

    if ($glance_backend == 'swift' and ! str2bool($swift)) {
      fail("Swift have to be enabled when it is used as a glance backend")
    }

    class {'::openstack::controller':
      db_host                       => $real_db_host,
      admin_email                   => $admin_email,
      admin_password                => $admin_password,
      auto_assign_floating_ip       => $auto_assign_floating_ip,
      cinder_db_password            => $cinder_db_password,
      cinder_user_password          => $cinder_user_password,
      cinder_bind_address           => $bind_address,
      external_bridge_name          => $external_bridge_name,
      fixed_range                   => $fixed_range,
      floating_range                => $floating_range,
      glance_db_password            => $glance_db_password,
      glance_user_password          => $glance_user_password,
      glance_api_servers            => "${bind_address}:9292",
      glance_registry_host          => $bind_address,
      glance_backend                => $glance_backend,
      swift_store_user              => 'services:glance',
      swift_store_key               => $glance_user_password,
      horizon                       => false,
      keystone_host                 => $bind_address,
      keystone_admin_token          => $keystone_admin_token,
      keystone_db_password          => $keystone_db_password,
      keystone_bind_address         => $bind_address,
      multi_host                    => $multi_host,
      network_manager               => $network_manager,
      nova_db_password              => $nova_db_password,
      nova_user_password            => $nova_user_password,
      nova_bind_address             => $bind_address,
      private_interface             => $private_interface,
      public_address                => $public_address,
      public_protocol               => $public_protocol,
      public_interface              => $public_interface,
      neutron                       => $neutron,
      neutron_user_password         => $neutron_user_password,
      neutron_db_password           => $neutron_db_password,
      neutron_auth_url              => "http://${bind_address}:35357/v2.0",
      allow_overlapping_ips         => $allow_overlapping_ips,
      bridge_interface              => $bridge_interface,
      rabbit_password               => $rabbit_password,
      secret_key                    => $secret_key,
      verbose                       => $verbose,
      firewall_driver               => $neutron_firewall_driver_real,
      ovs_local_ip                  => $priv_local_ip,
      require                       => Class['profile::openstack::setup'],
      mysql_root_password           => $mysql_root_password,
      metadata_shared_secret        => $metadata_shared_secret,
      allowed_hosts                 => $allowed_hosts,
      enable_neutron_server         => $enable_neutron_server,
      token_format                  => $keystone_token_format,
      internal_address              => $mgmt_ctrl_ip,
      vncproxy_host                 => $bind_address,
      rabbit_host                   => $mgmt_ctrl_ip,
      rabbit_hosts                  => $ha_rabbit_hosts,
      rabbit_cluster_nodes          => $ha_rabbit_cluster_nodes,
    }

    # MySQL Config
    $default_mysqld_settings = {'innodb_buffer_pool_size' => '1024M'}
    $real_mysqld_settings = merge($default_mysqld_settings, $mysqld_settings)
    mysql::server::config { 'openstack-controller':
      settings => {
        'mysqld' => $real_mysqld_settings,
      },
    }
    if ($config_ha) {
      mysql::server::config { 'openstack-controller-cluster':
        settings => {
          'mysqld' => {
            'binlog_format'                   => 'ROW',
            'innodb_autoinc_lock_mode'        => '2',
            'innodb_locks_unsafe_for_binlog'  => '1',
            'innodb_log_file_size'            => '50331648',
            'pid-file'                        => '/var/run/mysqld/mysqld.pid',
            'socket'                          => '/var/run/mysqld/mysqld.sock',
            'wsrep_provider'                  => '/usr/lib/libgalera_smm.so',
            'wsrep_cluster_name'              => "${::zone}_galera_cluster",
            'wsrep_cluster_address'           => "gcomm://${thenext_synced}",
            'wsrep_sst_auth'                  => "root:${mysql_root_password}",
            'wsrep_certify_nonPK'             => '1',
            'wsrep_convert_LOCK_to_trx'       => '0',
            'wsrep_auto_increment_control'    => '1',
            'wsrep_drupal_282555_workaround'  => '0',
            'wsrep_causal_reads'              => '0',
            'wsrep_sst_method'                => 'xtrabackup',
            'wsrep_node_address'              => $::ipaddress_eth0,
            'wsrep_node_incoming_address'     => $::ipaddress_eth0
          },
        },
      }
    }

    if (str2bool($swift) and str2bool($::keystone_available)) {
      include profile::openstack::swift::proxy
      Class['profile::openstack::firewall']
        -> Class['profile::openstack::swift::proxy']
    }
  }
}
