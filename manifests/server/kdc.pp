# === Class: kerberos::server::kdc
#
# Kerberos kdc configuration file definition.  Configures your
# kdc, including the kdc.conf file and Kerberos principals.
#
# === Authors
#
# Author Name <jason@rampaginggeek.com>
#
# Additions by <greg.1.anderson@greeknowe.org>
# Additions by Michael Weiser <michael.weiser@gmx.de>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::server::kdc(
  $realm = $kerberos::realm,
  $kdc_database_password = $kerberos::kdc_database_password,
  $kadmind_acls = $kerberos::kadmind_acls,
  $kdc_conf_path = $kerberos::kdc_conf_path,
  $kadm5_acl_path = $kerberos::kadm5_acl_path,
  $kdc_database_path = $kerberos::kdc_database_path,
  $kdc_stash_path = $kerberos::kdc_stash_path,

  $realm = $kerberos::realm,
  $kdc_ports = $kerberos::kdc_ports,
  $kdc_max_life = $kerberos::kdc_max_life,
  $kdc_max_renewable_life = $kerberos::kdc_max_renewable_life,
  $kdc_master_key_type = $kerberos::kdc_master_key_type,
  $kdc_supported_enctypes = $kerberos::kdc_supported_enctypes,
  $pkinit_anchors = $kerberos::pkinit_anchors_cfg,
  $kdc_pkinit_identity = $kerberos::kdc_pkinit_identity_cfg,
  $kdc_logfile = $kerberos::kdc_logfile_cfg,
  $kadmind_logfile = $kerberos::kadmind_logfile_cfg,
  $kdc_server_packages = $kerberos::kdc_server_packages,
) inherits kerberos {
  include kerberos::base

  package { 'krb5-kdc-server-packages' :
    ensure => present,
    name   => $kdc_server_packages,
    before => File['kdc.conf'],
  }

  file { 'kdc.conf':
    ensure  => file,
    path    => $kdc_conf_path,
    content => template('kerberos/kdc.conf.erb'),
    mode    => '0644',
    owner   => 0,
    group   => 0,
  }

  file { "/etc/krb5kdc":
    ensure => "directory",
  }

  file { 'kadm5.acl':
    ensure  => file,
    path    => $kadm5_acl_path,
    content => template('kerberos/kadm5.acl.erb'),
    mode    => '0644',
    owner   => 0,
    group   => 0,
    require => File['/etc/krb5kdc'],
  }

  file { "/var/lib/krb5kdc":
    ensure => "directory",
  }

  exec { "create_krb5kdc_principal":
    command => "/usr/sbin/kdb5_util -r $realm -P $kdc_database_password create -s",
    creates => "$kdc_database_path",
    require => [ File['/var/lib/krb5kdc'], File['krb5.conf'], File['kdc.conf'], Exec["initialize_dev_random"], ],
  }

  # Look up our users in hiera.  Create a principal for each one listed
  # for this realm.
  $kerberos_principals = hiera("kerberos_principals", [])
  create_resources('kerberos::addprinc',$kerberos_principals)

  # Look up our trusted realms from hiera.  Create trusted principal pairs
  # for each trusted realm that is not the realm of the current server.
  $trusted = hiera('trusted_realms', [])
  $trusted_realms = delete($trusted['realms'], $realm)
  if $trusted {
    kerberos::trust { $trusted_realms:
      this_realm => $realm,
      password => $trusted['password'],
    }
  }

  service { 'krb5-kdc':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File['kdc.conf'],
    require => Exec["create_krb5kdc_principal"],
  }
}
