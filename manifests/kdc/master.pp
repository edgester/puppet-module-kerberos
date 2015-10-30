# === Class: kerberos::kdc::master
#
# Kerberos master kdc: Sets up the server daemons using kerberos::server::kdc
# and kerberos::server::kadmind classes. Creates the master database and adds a
# cron job for updating the slaves.
#
# === Authors
#
# Jason Edgecombe <jason@rampaginggeek.com>
#
# Additions by <greg.1.anderson@greeknowe.org>
# Additions by Michael Weiser <michael.weiser@gmx.de>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::kdc::master (
  $realm = $kerberos::realm,

  $kadmind_enable = $kerberos::kadmind_enable,
  $kdc_slaves = $kerberos::kdc_slaves,
  $kdc_database_path = $kerberos::kdc_database_path,
  $kdc_database_password = $kerberos::kdc_database_password,
  $kdc_principals = $kerberos::kdc_principals,
  $kdc_trusted_realms = $kerberos::kdc_trusted_realms,

  $kdb5_util_path = $kerberos::kdb5_util_path,
) inherits kerberos {
  # at a minimum a master has a krb5kdc server
  include kerberos::server::kdc

  # convenience setting for enabling and disabling kadmind
  if $kadmind_enable {
    include kerberos::server::kadmind
  }

  # set up kprop cron job if we have slaves
  if $kdc_slaves {
    include kerberos::server::kprop
  }

  if ! $kdc_database_password {
    fail('kdc_database_password must be set')
  }

  require stdlib
  $kdc_database_dir = dirname($kdc_database_path)

  exec { 'create_krb5kdc_principal':
    command => "${kdb5_util_path} -r ${realm} -P \'${kdc_database_password}\' create -s",
    creates => $kdc_database_path,
    require => [ File[$kdc_database_dir, 'kdc.conf'], ],
  }

  # Look up our users in hiera. Create a principal for each one listed
  # for this realm.
  $kerberos_principals = hiera_hash('kerberos::principals', $kdc_principals)
  create_resources('kerberos::addprinc', $kerberos_principals)

  # KDC database must be created before we can start the KDC service and it
  # should be restarted if someone deleted its database from underneath it
  Exec['create_krb5kdc_principal'] ~> Service['krb5kdc']

  # KDC database must be created before *any* principals can be added - duh
  Exec['create_krb5kdc_principal'] -> Kerberos::Addprinc<||>

  # all principal-adding using kadmin.local should be done before we
  # start the KDC
  Kerberos::Addprinc<| local == true |> -> Service['krb5kdc']

  # Look up our trusted realms from hiera. Create trusted principal pairs
  # for each trusted realm that is not the realm of the current server.
  $trusted = hiera_hash('kerberos::trusted_realms', $kdc_trusted_realms)
  if $trusted {
    if $trusted['realms'] {
      $trusted_realms = delete($trusted['realms'], $realm)
    }
    if $trusted_realms {
      kerberos::trust { $trusted_realms:
        this_realm => $realm,
        password   => $trusted['password'],
      }
    }
  }
}
