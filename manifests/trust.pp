# == Type: kerberos::trust
#
# Creates a trust between two realms *on this KDC*. Needs to be done on both
# KDCs.
#
# To make this realm, $::realm trust realms EXAMPLE.COM and EXAMPLE.ORG:
#
# kerberos::trust { [ "EXAMPLE.COM", "EXAMPLE.ORG" ]:
#   this_realm => $::realm,
#   password => 'secretsecret',
# }
#
# The EXAMPLE.COM and EXAMPLE.ORG must have similar trust declarations
# with the same password.
#
# === Authors
#
# Author Name <greg.1.anderson@greenknowe.org>
#
# === Copyright
#
# Copyright 2014 Jason Edgecombe (Copyright assigned by original author)
#
define kerberos::trust($trusted_realm = $title, $this_realm, $password) {
  kerberos::addprinc { "krbtgt/${this_realm}@${trusted_realm}":
    password => $password,
    flags    => '-requires_preauth',
  }

  kerberos::addprinc { "krbtgt/${trusted_realm}@${this_realm}":
    password => $password,
    flags    => '-requires_preauth',
  }
}
