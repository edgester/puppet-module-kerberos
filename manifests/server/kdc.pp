# === Class: kerberos::server::kdc
#
# Kerberos kdc service. Installs and starts the KDC service. Uses
# kerberos::server::base to create kdc.conf. Although it starts the service
# it does not create a database. Use kerberos::kdc::master or
# kerberos::kdc:slave to actually set up functioning KDCs.
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
class kerberos::server::kdc (
  $kdc_database_path = $kerberos::kdc_database_path,
  $kdc_server_package = $kerberos::kdc_server_package,
  $kdc_service_name = $kerberos::kdc_service_name,
) inherits kerberos {
  # pkinit packages
  include kerberos::base
  # kdc.conf
  include kerberos::server::base

  ensure_resource('package', $kdc_server_package, { ensure => present, before => File['kdc.conf']})

  # is created here for both master and slave
  require stdlib
  $kdc_database_dir = dirname($kdc_database_path)
  ensure_resource('file', $kdc_database_dir, { ensure => 'directory' })

  service { 'krb5kdc':
    ensure     => running,
    name       => $kdc_service_name,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => File[$kdc_database_dir],
    subscribe  => File['kdc.conf'],
  }

  # all adding of principals using kadmin.local should be done before the
  # KDC is started
  Kerberos::Addprinc<| local == true |> -> Service['krb5kdc']

  # installed in kerberos::base if enabled
  Package<| tag == 'krb5-pkinit-packages' |> -> Service['krb5kdc']
}
