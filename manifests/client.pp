# === Authors
#
# Author Name <jason@rampaginggeek.com>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class krb5::client($realm = 'EXAMPLE.COM', $kdc = [], $admin_server = []) inherits krb5::base {
  include krb5::base

  package { 'krb5-client-packages' :
    ensure => present,
    name   => $krb5::params::client_packages,
    before => File['kdc.conf'],
  }

  file { 'krb5.conf':
    path    => $krb5::params::krb5_conf_path,
    ensure  => file,
    content => template("krb5/krb5.conf.erb"),
    mode    => 644,
    owner   => 0,
    group   => 0,
  }
}
