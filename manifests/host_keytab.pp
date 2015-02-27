# === Class: kerberos::server::host_keytab
#
# Wrapper class for Bigtop compatibility
#
# === Authors
#
# Michael Weiser <michael.weiser@gmx.de>
#
define kerberos::host_keytab($princs = [ $title ], $spnego = false,
  $owner = $title, $group = 0, $mode = '0400',
  $host_ticket_cache_ccname = $kerberos::host_ticket_cache_ccname,
) {
  # hack to get $kerberos::host_ticket_cache_ccname initialised
  include kerberos

  require stdlib
  $actual_principals = suffix($princs, "/${fqdn}")
  $keytab = "/etc/${title}.keytab"
  $ktadds = prefix($actual_principals, "${keytab}@")
  kerberos::addprinc_keytab_ktadd { $ktadds:
    local => false,
    keytab_owner  => $owner,
    keytab_group  => $group,
    keytab_mode   => $mode,
    kadmin_ccache => $kerberos::host_ticket_cache_ccname,
  }

  if $spnego {
    # workaround for empty princs array
    if $princs == [] {
      kerberos::keytab { $keytab:
        owner => $owner,
        group => $group,
        mode  => $mode,
      }
    }

    # make a separate keytab for HTTP, but only once
    $keytab_http = '/etc/hadoop-spnego.keytab'
    $principal_http = "HTTP/${fqdn}"
    $ktadd_http = "${keytab_http}@${principal_http}"
    if !defined(Kerberos::Addprinc_keytab_ktadd[$ktadd_http]) {
      kerberos::addprinc_keytab_ktadd { $ktadd_http:
        local => false,
        kadmin_ccache => $kerberos::host_ticket_cache_ccname,
      }
    }

    # create the HTTP keytab and then interject the HTTP principal between
    # keytab creation and first principal addition so that we're finished with
    # this when the actual addprinc_keytab_ktadd is finished
    Kerberos::Addprinc_keytab_ktadd[$ktadd_http] ->
    Kerberos::Keytab[$keytab] ->
    exec { "krb5-ktutil-${keytab_http}-${keytab}":
      command => "ktutil <<EOF
rkt ${keytab_http}
wkt ${keytab}
EOF",
      path    => [ "/bin", "/usr/bin" ],
      unless  => "klist -k '${keytab}' | grep ' ${principal_http}@'",
    } ->
    Kerberos::Ktadd[$ktadds]
  }
}
