# == Class: kerberos::client
#
# Install and configure the client, mostly krb5.conf.
#
# === Authors
#
# Author Name <jason@rampaginggeek.com>
# Additions by Michael Weiser <michael.weiser@gmx.de>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::client (
  $krb5_conf_path = $kerberos::krb5_conf_path,
  $realm = $kerberos::realm,
  $domain_realm = $kerberos::domain_realm,
  $kdcs = $kerberos::kdcs,
  $master_kdc = $kerberos::master_kdc,
  $admin_server = $kerberos::admin_server,
  $allow_weak_crypto = $kerberos::allow_weak_crypto,
  $forwardable = $kerberos::forwardable,
  $proxiable = $kerberos::proxiable,
  $pkinit_anchors = $kerberos::pkinit_anchors_cfg,

  $client_packages = $kerberos::client_packages,
) inherits kerberos {
  include kerberos::base

  # Provide default content for domain_realm if the user did not
  # specify anything.
  if empty($domain_realm) {
    $realm_in_lowercase = downcase($realm)
    $default_domain = ".${realm_in_lowercase}"
    $domain_realm_list = { "$default_domain" => "$realm" }
  }
  else {
    $domain_realm_list = $domain_realm
  }

  package { 'krb5-client-packages' :
    ensure => present,
    name   => $client_packages,
    before => File['krb5.conf'],
  }

  $krb5_conf_dir = dirname($krb5_conf_path)
  if !defined(File[$krb5_conf_dir]) {
    file { $krb5_conf_dir: ensure => directory }
  }

  file { 'krb5.conf':
    ensure  => file,
    path    => $krb5_conf_path,
    content => template('kerberos/krb5.conf.erb'),
    mode    => '0644',
    owner   => 0,
    group   => 0,
    require => File[$krb5_conf_dir],
  }
}
