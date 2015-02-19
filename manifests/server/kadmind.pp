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
  $kadmin_server_packages = $kerberos::kadmin_server_packages,
) inherits kerberos {
  package { 'krb5-kadmind-server-packages' :
    ensure => present,
    name   => $kadmin_server_packages,
  }

  service { 'krb5-admin-server':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File['krb5.conf'],
  }
}
