# === Authors
#
# Author Name <jason@rampaginggeek.com>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::server::kadmind {
  include kerberos::base

  package { 'krb5-kadmind-server-packages' :
    ensure => present,
    name   => $kerberos::params::kadmin_server_packages,
  }

  service { 'krb5-admin-server':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File['krb5.conf'],
    require => Service["krb5-kdc"],
  }
}
