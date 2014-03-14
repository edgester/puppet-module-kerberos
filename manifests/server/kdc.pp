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
#   It is best to store passwords in Hiera; that way,
#   you can have a set of test credentials (e.g. in
#   'virtual_true.yaml'), and a different set of credentials
#   for production servers.
#
#     kdc1.realmone.local.yaml:
#     ---
#     kerberos::server::kdc::master_password: secretmasterpassword
#
#     kerberos_principals_REALMONE.LOCAL:
#       user1:
#         password: secretsecret
#
#     kerberos_principals_EXAMPLE.COM:
#       user2:
#         password: p4ssw0rd!
#
#     trusted_realms:
#       realms:
#         - INSECURE.LOCAL
#         - EXAMPLE.COM
#         - EXAMPLE.ORG
#       password: tgtsecret
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

  # In some environments (e.g. virtual machines), /dev/random produces
  # no data, breaking kdb5_util create.  We work around this problem
  # by linking /dev/urandom to /dev/random.  This reduces entropy and
  # therefore security substantially, so we do not want to do this unless
  # necessary.
  # See: https://dev.openwrt.org/ticket/10713
  if $::virtual {
    exec { "initialize_dev_random":
      command => "rm -f /dev/random && ln -fs /dev/urandom /dev/random",
    }
  }
  else {
    exec { "initialize_dev_random":
      command => "echo Using system's /dev/random",
    }
  }

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
    require => [ File['/var/lib/krb5kdc'], Exec["initialize_dev_random"], ],
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
