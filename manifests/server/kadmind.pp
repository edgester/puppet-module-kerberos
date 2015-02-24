# === Class: kerberos::server::kadmind
#
# Kerberos admin service. Installs and starts the kadmin service. Does not
# create the master KDC database though. Use kerberos::kdc::master to set up
# functioning KDCs.
#
# === Authors
#
# Author Name <jason@rampaginggeek.com>
# Additions by Michael Weiser <michael.weiser@gmx.de>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::server::kadmind (
  $kadm5_acl_path = $kerberos::kadm5_acl_path,
  $kadmind_acls = $kerberos::kadmind_acls,
  $kadmin_service_name = $kerberos::kadmin_service_name,
) inherits kerberos {
  include kerberos::server::kadmind_kprop

  require stdlib
  $kadm5_acl_dir = dirname($kadm5_acl_path)
  if !defined(File[$kadm5_acl_dir]) {
    file { $kadm5_acl_dir: ensure => 'directory' }
  }

  file { 'kadm5.acl':
    ensure  => file,
    path    => $kadm5_acl_path,
    content => template('kerberos/kadm5.acl.erb'),
    mode    => '0644',
    owner   => 0,
    group   => 0,
    require => File[$kadm5_acl_dir],
  }

  service { 'kadmind':
    ensure     => running,
    name       => $kadmin_service_name,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Exec['create_krb5kdc_principal'],
    subscribe  => [ File['kdc.conf', 'kadm5.acl'], Exec['create_krb5kdc_principal'] ],
  }

  # all adding of principals using kadmin can only be done after kadmind
  # is started
  Service['kadmind'] -> Kerberos::Addprinc<| local == false |>
}
