# === Class: kerberos::server::kadmind_kprop
#
# Kerberos KDC kadmin and kpropd common elements: Installs kadmind packages
# which also contain kprop.
#
# === Authors
#
# Jason Edgecombe <jason@rampaginggeek.com>
#
# Additions by <greg.1.anderson@greeknowe.org>
# Additions by Michael Weiser <michael.weiser@gmx.de>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::server::kadmind_kprop (
  $kadmin_server_package = $kerberos::kadmin_server_package,
) inherits kerberos {
  # kadmind and kprop both only make sense on a master KDC. So pull in
  # general common server config for KDCs.
  include kerberos::server::base

  if (!defined(Package[$kadmin_server_package])) {
    package { $kadmin_server_package:
      ensure => present,
    }
  }
}
