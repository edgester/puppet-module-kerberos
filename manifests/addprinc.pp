# === Authors
#
# Author Name <greg.1.anderson@greenknowe.org>
#
# === Copyright
#
# Copyright 2014 Jason Edgecombe (Copyright assigned by original author)
#
define kerberos::addprinc($principal_name = $title, $password = 'password', $flags = '') {
  exec { "add_principal_$principal_name":
    command => "kadmin.local -w '$password' -q 'addprinc $flags $principal_name'",
    require => [ Package['krb5-kadmind-server-packages'], Exec['create_krb5kdc_principal'] ],
  }
}
