# === Authors
#
# Author Name <jason@rampaginggeek.com>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class krb5::server::kdc {
  include krb5::base

  package { 'krb5-kdc-server-packages' :
    ensure => present,
    name   => $krb5::params::kdc_server_packages,
  }
}
