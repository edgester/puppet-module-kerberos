# === Authors
#
# Author Name <jason@rampaginggeek.com>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::client($realm = 'EXAMPLE.COM', $domain_realm = {}, $kdc = [], $admin_server = [],
  $allow_weak_crypto = false) inherits kerberos::base {

  include kerberos::base

  package { 'krb5-client-packages' :
    ensure => present,
    name   => $kerberos::params::client_packages,
    before => File['krb5.conf'],
  }

  file { 'krb5.conf':
    ensure  => file,
    path    => $kerberos::params::krb5_conf_path,
    content => template('kerberos/krb5.conf.erb'),
    mode    => '0644',
    owner   => 0,
    group   => 0,
  }
}
