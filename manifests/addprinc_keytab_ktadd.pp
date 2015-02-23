# == Type: kerberos::addprinc_keytab_ktadd
#
# Wrapper around addprinc, keytab and ktadd. Uses if defined() to only define
# resources that aren't defined yet. That way, they can be pre-defined from the
# outside, forcing e.g. specific permissions.
#
# === Authors
#
# Michael Weiser <michael.weiser@gmx.de>
#
define kerberos::addprinc_keytab_ktadd(
  $keytab = regsubst($title, '@.*$', ''),
  $principal = regsubst($title, '^[^@]*@', ''),
  $local = true, $kadmin_ccache = undef, $kadmin_keytab = undef,
  $kadmin_tries = undef, $kadmin_try_sleep = undef,
  # only here for host_keytab - define keytab directly if specific permissions
  # are desired
  $keytab_owner = 0, $keytab_group = 0, $keytab_mode = '0400'
) {
  if $local == false {
    include kerberos::host_ticket_cache
    Kerberos::Ticket_cache['krb5-cache-puppet'] ->
      Kerberos::Addprinc[$principal]
  }

  # this is why we can only do one principal at a time - if we ever find a way
  # to check for multiple resources being defined already, we can enhance this
  # functions to do multiple principals per keytab in one go.
  if !defined(Kerberos::Addprinc[$principal]) {
    kerberos::addprinc { $principal:
      local         => $local,
      kadmin_ccache => $kadmin_ccache,
      keytab        => $kadmin_keytab,
      tries         => $kadmin_tries,
      try_sleep     => $kadmin_try_sleep,
    }
  }

  if !defined(Kerberos::Keytab[$keytab]) {
    kerberos::keytab { $keytab:
      owner => $keytab_owner,
      group => $keytab_group,
      mode  => $keytab_mode,
    }
  }

  $ktadd = "${keytab}@${principal}"
  if !defined(Kerberos::Ktadd[$ktadd]) {
    kerberos::ktadd { $ktadd:
      keytab           => $keytab,
      principal        => $principal,
      local            => $local,
      kadmin_ccache    => $kadmin_ccache,
      kadmin_keytab    => $kadmin_keytab,
      kadmin_tries     => $kadmin_tries,
      kadmin_try_sleep => $kadmin_try_sleep,
    }
  }

  Kerberos::Addprinc[$principal] ->
    Kerberos::Keytab[$keytab] ->
    Kerberos::Ktadd[$ktadd]
}
