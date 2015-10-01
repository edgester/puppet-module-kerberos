# === Type: kerberos::addprinc
#
# Adds a kerberos principal to the KDC database. Supports use of kadmin.local
# or kadmin. The latter supports use of a ticket cache or a keytab file.
#
# === Authors
#
# Author Name <greg.1.anderson@greenknowe.org>
# Additions by Michael Weiser <michael.weiser@gmx.de>
#
# === Copyright
#
# Copyright 2014 Jason Edgecombe (Copyright assigned by original author)
#
define kerberos::addprinc($principal_name = $title, $password = undef, $flags = '',
  $local = true, $kadmin_ccache = undef, $keytab = undef,
  $tries = undef, $try_sleep = undef,
) {
  if $local {
    # if we're gonna run kadmin.local we better make sure it's
    # installed
    include kerberos::server::kadmind_kprop
    $kadmin = 'kadmin.local'
  } else {
    # if we're gonna run kadmin we better make sure it's installed
    # and configured
    include kerberos::client
    $kadmin = 'kadmin'

    $ccache_par = $kadmin_ccache ? {
      undef => '',
      default => "-c '${kadmin_ccache}'"
    }

    $keytab_par = $keytab ? {
      undef => '',
      default => "-k -t '${keytab}'"
    }
  }

  $password_par = $password ? {
    undef => '-nokey',
    default => "-pw ${password}"
  }

  exec { "add_principal_${principal_name}":
    command   => "${kadmin} ${ccache_par} ${keytab_par} -q 'addprinc ${flags} ${password_par} ${principal_name}'",
    path      => [ '/usr/sbin', '/usr/bin' ],
    require   => $local ? {
      true    => [ Package['krb5-kadmind-server-packages'],
        Exec['create_krb5kdc_principal'], ],
      default => [ Package['krb5-client-packages'], File['krb5.conf'] ],
    },
    tries     => $kadmin_tries,
    try_sleep => $kadmin_try_sleep,
  }
}
