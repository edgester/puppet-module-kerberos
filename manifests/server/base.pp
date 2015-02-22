# === Class: kerberos::server::base
#
# Kerberos KDC base elements: Generates kdc.conf needed by kdc and kadmind.
#
# === Authors
#
# Author Name <jason@rampaginggeek.com>
#
# Additions by <greg.1.anderson@greeknowe.org>
# Additions by Michael Weiser <michael.weiser@gmx.de>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::server::base (
  $kdc_conf_path = $kerberos::kdc_conf_path,

  $realm = $kerberos::realm,
  $kdc_ports = $kerberos::kdc_ports,
  $kdc_database_path = $kerberos::kdc_database_path,
  $kdc_stash_path = $kerberos::kdc_stash_path,
  $kdc_max_life = $kerberos::kdc_max_life,
  $kdc_max_renewable_life = $kerberos::kdc_max_renewable_life,
  $kdc_master_key_type = $kerberos::kdc_master_key_type,
  $kdc_supported_enctypes = $kerberos::kdc_supported_enctypes,
  $pkinit_anchors = $kerberos::pkinit_anchors_cfg,
  $kdc_pkinit_identity = $kerberos::kdc_pkinit_identity_cfg,
  $kdc_logfile = $kerberos::kdc_logfile_cfg,
  $kadmind_logfile = $kerberos::kadmind_logfile_cfg,
) inherits kerberos {
  require stdlib
  $kdc_conf_dir = dirname($kdc_conf_path)
  if !defined(File[$kdc_conf_dir]) {
    file { $kdc_conf_dir: ensure => 'directory' }
  }

  file { 'kdc.conf':
    ensure  => file,
    path    => $kdc_conf_path,
    content => template('kerberos/kdc.conf.erb'),
    mode    => '0644',
    owner   => 0,
    group   => 0,
    require => File[$kdc_conf_dir],
  }
}
