# == Class: kerberos::host_ticket_cache
#
# Initialise a ticket cache for the host to be used especially by kadmin.
#
# === Authors
#
# Michael Weiser <michael.weiser@gmx.de>
#

class kerberos::host_ticket_cache (
  $host_ticket_cache_ccname = $kerberos::host_ticket_cache_ccname,
  $host_ticket_cache_service = $kerberos::host_ticket_cache_service,
  $host_ticket_cache_principal = $kerberos::host_ticket_cache_principal,
) inherits kerberos {
  # if this is the KDC, then obviously the machine principals must be
  # created first
  Kerberos::Addprinc<| local == true |> ->
    Kerberos::Ticket_cache["krb5-cache-puppet"]

  kerberos::ticket_cache { "krb5-cache-puppet":
    ccname    => $host_ticket_cache_ccname,
    pkinit    => true,
    principal => $host_ticket_cache_principal,
    service   => $host_ticket_cache_service,
  }
}
