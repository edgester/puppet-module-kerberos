# === Type: kerberos::ktadd
#
# Adds a kerberos key to a keytab. Supports use of kadmin.local or kadmin. The
# latter supports use of a ticket cache or a keytab file.
#
# === Authors
#
# Michael Weiser <michael.weiser@gmx.de>
#

# infer principal and keytab file names from title if not given explicitly,
# syntax: <keytab>@<principal_possibly_containing_more_@s>
define kerberos::ktadd(
  $keytab = regsubst($title, "@.*$", ""),
  $principal = regsubst($title, "^[^@]*@", ""),
  $local = true, $reexport = false,
  $kadmin_ccache = undef, $kadmin_keytab = undef,
  $kadmin_tries = undef, $kadmin_try_sleep = undef,
) {
  if $local {
    $kadmin = 'kadmin.local'
    Package['krb5-kadmind-server-packages'] -> Exec["ktadd_${keytab}_${principal}"]
    Exec['create_krb5kdc_principal'] -> Exec["ktadd_${keytab}_${principal}"]
  } else {
    $kadmin = 'kadmin'

    $ccache_par = $kadmin_ccache ? {
      undef   => '',
      default => "-c '${kadmin_ccache}'"
    }

    $keytab_par = $kadmin_keytab ? {
      undef   => '',
      default => "-k '${kadmin_keytab}'"
    }

    Package['krb5-client-packages'] -> Exec["ktadd_${keytab}_${principal}"]
    File['krb5.conf'] -> Exec["ktadd_${keytab}_${principal}"]
  }

  if $reexport {
    $unless = undef
  } else {
    $unless = "klist -k '${keytab}' | grep ' ${principal}@'"
  }

  exec { "ktadd_${keytab}_${principal}":
    command   => "${kadmin} ${ccache_par} ${keytab_par} -q 'ktadd -k ${keytab} ${principal}'",
    unless    => $unless,
    path      => [ '/bin', '/usr/bin', '/usr/bin', '/usr/sbin' ],
    require   => File[$keytab],
    tries     => $kadmin_tries,
    try_sleep => $kadmin_try_sleep,
  }
}
