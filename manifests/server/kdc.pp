# === Class: kerberos::server::kdc
#
# Kerberos kdc configuration file definition.  Configures your
# kdc, including the kdc.conf file and Kerberos principals.
#
# === Parameters
#
#   $realm:
#     The Kerberos realm (e.g. 'EXAMPLE.COM')
#   $master_password:
#     The master password for the kdc database.  See: http://bit.ly/1cWynBB
#   $acl:
#     Access control list entries.  See: http://bit.ly/1j0rP7K
#   $kdc_conf_path:
#     Path to kdc.conf.  See: templates/kdc.conf.erb
#   $kadm5_acl_path:
#     Path to kadm5.acl.  See: templates/kadm5.acl
#   $krb5kdc_database_path:
#     Path to kdc principals database.
#   $admin_keytab_path:
#     Path to admin keytab.  See: http://bit.ly/1qR8vLj
#   $key_stash_path:
#     Path to key stash.
#   $use_debug_random:
#     Set to true on debug virtual systems if /dev/random
#     does not produce any data.
#
# === Sample Usage
#
#     class {'kerberos::server::kdc':
#       realm => "REALMONE.LOCAL",
#     }
#
#   It is best to store passwords in Hiera; see README file for details.
#
# === Authors
#
# Author Name <jason@rampaginggeek.com>
#
# Additions by <greg.1.anderson@greeknowe.org>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::server::kdc(
  $realm = 'EXAMPLE.COM',
  $master_password,
  $acl = { "*/admin@$realm" => '*' },
  $kdc_conf_path = $kerberos::params::kdc_conf_path,
  $kadm5_acl_path = $kerberos::params::kadm5_acl_path,
  $krb5kdc_database_path = $kerberos::params::krb5kdc_database_path,
  $admin_keytab_path = $kerberos::params::admin_keytab_path,
  $key_stash_path = $kerberos::params::key_stash_path,
) inherits kerberos::base {
  include kerberos::base

  package { 'krb5-kdc-server-packages' :
    ensure => present,
    name   => $kerberos::params::kdc_server_packages,
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
    command => "/usr/sbin/kdb5_util -r $realm -P $master_password create -s",
    creates => "$krb5kdc_database_path",
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
