# === Class: kerberos::server::host_keytab
#
# Wrapper class for Bigtop compatibility
#
# === Authors
#
# Michael Weiser <michael.weiser@gmx.de>
#
define kerberos::host_keytab($princs = [ $title ], $spnego = false,
  $owner = $title, $group = 0, $mode = '0600',
  $host_ticket_cache_ccname = $kerberos::host_ticket_cache_ccname,
  $realm = $kerberos::realm,
) {
  # hack to get $kerberos::host_ticket_cache_ccname initialised
  include kerberos

  require stdlib
  $actual_principals = suffix($princs, "/${::fqdn}")
  $keytab = "/etc/${title}.keytab"
  $ktadds = prefix($actual_principals, "${keytab}@")
  kerberos::addprinc_keytab_ktadd { $ktadds:
    local         => false,
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
    $principal_http = "HTTP/${::fqdn}"
    $ktadd_http = "${keytab_http}@${principal_http}"
    $ktadd_http_exec = "ktadd_${keytab_http}_${principal_http}"
    if !defined(Kerberos::Addprinc_keytab_ktadd[$ktadd_http]) {
      kerberos::addprinc_keytab_ktadd { $ktadd_http:
        local         => false,
        kadmin_ccache => $kerberos::host_ticket_cache_ccname,
      }
    }

    # commands to remove old keys from the target keytab and copy over new ones
    $remoldkeys_princ = $actual_principals[0]
    $remoldkeys = "kadmin -k -t '${keytab}' -p '${remoldkeys_princ}' \
      -q 'ktrem -k ${keytab} ${principal_http} all'"
    $copykeys = "ktutil <<EOF
rkt ${keytab_http}
wkt ${keytab}
EOF"

    # commands that extract kvnos of a principal from the keytabs and format
    # them to be string-comparable
    $normkvnos = "awk '{print \$1}' | sort | tr '\\n' ' '"
    $getkvnos = "grep ' ${principal_http}@${realm}' | ${normkvnos}"
    $getkvnos_kt = "klist -k '${keytab}' | ${getkvnos}"
    $getkvnos_http = "klist -k '${keytab_http}' | ${getkvnos}"

    # create the HTTP keytab and then interject the HTTP principal between
    # keytab creation and first principal addition so that we're finished with
    # this when the actual addprinc_keytab_ktadd is finished
    $ktadd_execs = prefix(prefix($actual_principals, "${keytab}_"), 'ktadd_')
    Exec[$ktadd_http_exec] ->
    Kerberos::Keytab[$keytab] ->
    exec { "krb5-ktutil-${keytab_http}-${keytab}":
      command => "${remoldkeys} ; ${copykeys}",
      path    => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
      unless  => "test \"`${getkvnos_kt}`\" = \"`${getkvnos_http}`\"",
    } ->
    Exec[$ktadd_execs]
  }
}
