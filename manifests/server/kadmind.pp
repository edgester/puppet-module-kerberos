# === Authors
#
# Author Name <jason@rampaginggeek.com>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class krb5::server::kadmind {
  include krb5::base

  package { 'krb5-kadmind-server-packages' :
    ensure => present,
    name   => $krb5::params::kadmin_server_packages,
  }
}
