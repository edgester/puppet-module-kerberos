# === Authors
#
# Author Name <jason@rampaginggeek.com>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::server::kdc($realm = 'EXAMPLE.COM') inherits kerberos::base {
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

  service { 'krb5-kdc':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File['kdc.conf'],
  }
}
