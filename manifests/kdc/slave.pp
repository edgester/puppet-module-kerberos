# === Class: kerberos::kdc::slave
#
# Kerberos slave KDC: Sets up the server daemons using kerberos::server::kdc
# and kerberos::server::kpropd classes.
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
class kerberos::kdc::slave (
  $kdc_slaves = $kerberos::kdc_slaves,
  $kdc_database_path = $kerberos::kdc_database_path,
  $kdc_database_password = $kerberos::kdc_database_password,
  $kdc_stash_path = $kerberos::kdc_stash_path,
) inherits kerberos {
  # at a minimum a slave has krb5kdc and kpropd server
  include kerberos::server::kdc
  include kerberos::server::kpropd

  # set up kprop cron job if we have slaves
  if $kdc_slaves {
    include kerberos::server::kprop
  }

  if $kdc_database_password {
    $db_password = $kdc_database_password
  } else {
    $db_password = fail('kdc_data_password must be set')
  }

  # funky: Wait for someone to create our database before starting the KDC. In
  # this case that someone is kpropd. Should only ever cause a real wait if
  # we're bootstrapping and the database doesn't exist yet.
  Service['kpropd'] ->
  exec { 'krb5-wait-for-database':
    command   => "test -f '$kdc_database_path'",
    path      => [ '/bin', '/usr/bin' ],
    tries     => 10,
    try_sleep => 30,
  } ->
  exec { 'krb5-stash-database-pw':
    command => "echo '${db_password}' | ${kdb5_util_path} stash",
    path => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
    creates => $kdc_stash_path,
  } ~>
  Service['krb5kdc']
}
