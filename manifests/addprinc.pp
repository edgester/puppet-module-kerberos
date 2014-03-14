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
    command => "kadmin.local -e 'des3-hmac-sha1:normal des-cbc-crc:v4' -w '$password' -q 'addprinc $flags $principal_name'"
  }
}
