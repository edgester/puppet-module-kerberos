# === Class: kerberos::server::kprop
#
# Kerberos kprop program: Adds a cron job for updating the slave servers.
#
# === Authors
#
# Jason Edgecombe <jason@rampaginggeek.com>
#
# Additions by <greg.1.anderson@greeknowe.org>
# Additions by Michael Weiser <michael.weiser@gmx.de>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::server::kprop (
  $kprop_cron_path = $kerberos::kprop_cron_path,
  $kprop_cron_hour = $kprop_cron_hour,
  $kprop_cron_minute = $kerberos::kprop_cron_minute,
  $kprop_keytab = $kerberos::kprop_keytab,
  $kprop_principal = $kerberos::kprop_principal,

  $kdc_slaves = $kerberos::kdc_slaves,
  $kdc_database_path = $kerberos::kdc_database_path,
  $kprop_path = $kerberos::kprop_path,
  $kdb5_util_path = $kerberos::kdb5_util_path,

  $pkinit_anchors = $kerberos::pkinit_anchors,
  $host_ticket_cache_ccname = $kerberos::host_ticket_cache_ccname,

  # facter fact
  $kerberos_bootstrap = $::kerberos_bootstrap,
) inherits kerberos {
  include kerberos::server::kadmind_kprop

  # if we have pkinit we can automatically create the keytab for kprop
  $ktadd = "${kprop_keytab}@${kprop_principal}"
  if $pkinit_anchors and !defined(Kerberos::Addprinc_keytab_ktadd[$ktadd]) {
    kerberos::addprinc_keytab_ktadd { $ktadd:
      local => false,
      kadmin_ccache => $host_ticket_cache_ccname,
    } -> Cron['kprop']
  }

  require stdlib
  # needed in the kprop template
  $kdc_database_dir = dirname($kdc_database_path)

  $kprop_cron_dir = dirname($kprop_cron_path)
  if !defined(File[$kprop_cron_dir]) {
    file { $kprop_cron_dir: ensure => directory }
  }

  file { 'kprop.cron':
    ensure  => file,
    path    => $kprop_cron_path,
    content => template('kerberos/kprop.cron.erb'),
    mode    => '0755',
    owner   => 0,
    group   => 0,
    require => File[$kprop_cron_dir],
  }

  cron { 'kprop':
    command => $kprop_cron_path,
    user    => 'root',
    hour    => $kprop_cron_hour,
    minute  => $kprop_cron_minute,
  }

  if $kerberos_bootstrap {
    exec { 'kprop-force':
      command   => $kprop_cron_path,
      user      => 'root',
      tries     => 30,
      try_sleep => 10,
      # you can't do a bootstrap without a keytab for kprop
      require   => Kerberos::Ktadd[$ktadd]
    }
  }
}
