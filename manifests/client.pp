# === Authors
#
# Author Name <jason@rampaginggeek.com>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::client($realm = 'EXAMPLE.COM', $kdc = [], $admin_server = []) inherits kerberos::base {
  include kerberos::base

  package { 'krb5-client-packages' :
    ensure => present,
    name   => $kerberos::params::client_packages,
    before => File['kdc.conf'],
  }

  file { 'krb5.conf':
    path    => $kerberos::params::krb5_conf_path,
    ensure  => file,
    content => template("kerberos/krb5.conf.erb"),
    mode    => 644,
    owner   => 0,
    group   => 0,
  }
}
