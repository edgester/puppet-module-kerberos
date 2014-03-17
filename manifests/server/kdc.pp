# === Class: kerberos::server::kdc
#
# Kerberos kdc configuration file definition.  Configures your
# kdc, including the kdc.config file and Kerberos principals.
#
# === Parameters
#
#   $realm:
#     The Kerberos realm (e.g. 'EXAMPLE.COM')
#   $master_password:
#     The master password for the kdc database.
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
class kerberos::server::kdc($realm = 'EXAMPLE.COM', $master_password) inherits kerberos::base {
  include kerberos::base

  package { 'krb5-kdc-server-packages' :
    ensure => present,
    name   => $kerberos::params::kdc_server_packages,
    before => File['kdc.conf'],
  }

  file { 'kdc.conf':
    ensure  => file,
    path    => $kerberos::params::kdc_conf_path,
    content => template('kerberos/kdc.conf.erb'),
    mode    => '0644',
    owner   => 0,
    group   => 0,
  }

  file { "/var/lib/krb5kdc":
    ensure => "directory",
  }

  exec { "create_krb5kdc_principal":
    command => "/usr/sbin/kdb5_util -r $realm -P $master_password create -s",
    creates => "/var/lib/krb5kdc/principal",
    require => File['/var/lib/krb5kdc'],
  }

  # Look up our users in hiera.  Create a principal for each one listed
  # for this realm.
  $kerberos_principals = hiera("kerberos_principals_$realm", [])
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
