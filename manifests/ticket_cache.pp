# === Type: kerberos::ticket_cache
#
# Requests a TGT and puts it in a ticket cache. Supports use of a keytab file
# or PKINIT.
#
# === Authors
#
# Michael Weiser <michael.weiser@gmx.de>
#
define kerberos::ticket_cache ($ccname = $title,
  $principal = '',
  $keytab = undef,
  $service = undef,
  $pkinit = false,
  $pkinit_cert = "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
  $pkinit_key = "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",

  $client_packages = $kerberos::client_packages,
  $krb5_conf_path = $kerberos::krb5_conf_path,

  # facter fact
  $kerberos_bootstrap = $::kerberos_bootstrap,
) {
  # this needs to be a client in order to run kinit and kadmin
  include kerberos::client

  $keytab_par = $keytab ? {
    undef   => '',
    default => " -k -t '${keytab}'"
  }

  $pkinit_par = $pkinit ? {
    undef   => '',
    default => " -X 'X509_user_identity=FILE:${pkinit_cert},${pkinit_key}'"
  }

  $service_par = $service ? {
    undef   => '',
    default => "-S '${service}'"
  }

  $try_sleep = $kerberos_bootstrap ? {
    '1'     => 60,
    default => 10
  }

  $kinit_cmd = "kinit -c '${ccname}' ${keytab_par} ${pkinit_par} ${service_par}"
  exec { "ticket_cache_${title}":
    command     => "${kinit_cmd} ${principal}",
    path        => '/usr/bin',
    environment => "KRB5_CONFIG=${krb5_conf_path}",
    require     => [ Package[$client_packages], File['krb5.conf'] ],
    # always recreate (for now) to avoid expired tickets
    # creates => $ccname
    # if we're bootstrapping no KDC might be up yet and even if not
    # it might just be rebooting
    tries       => 30,
    try_sleep   => $try_sleep,
  }
}
