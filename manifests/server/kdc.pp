# === Authors
#
# Author Name <jason@rampaginggeek.com>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class krb5::server::kdc($realm = 'EXAMPLE.COM') inherits krb5::base {
  include krb5::base

  package { 'krb5-kdc-server-packages' :
    ensure => present,
    name   => $krb5::params::kdc_server_packages,
    before => File['kdc.conf'],
  }

  file { 'kdc.conf':
    path    => $krb5::params::kdc_conf_path,
    ensure  => file,
    content => template("krb5/kdc.conf.erb"),
    mode    => 644,
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
