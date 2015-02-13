# == Class: kerberos::base
#
# === Authors
#
# Author Name <jason@rampaginggeek.com>
# Additions by Michael Weiser <michael.weiser@gmx.de>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::base (
  $pkinit_anchors = $kerberos::pkinit_anchors,
  $pkinit_packages = $kerberos::pkinit_packages,
) inherits kerberos {
  if $pkinit_anchors {
    package { 'krb5-pkinit-packages':
      ensure => present,
      name   => $pkinit_packages,
    }
  }
}
