# === Authors
#
# Author Name <jason@rampaginggeek.com>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos::client($realm = 'EXAMPLE.COM', $domain_realm = {}, $kdc = [], $admin_server = [],
  $allow_weak_crypto = false) inherits kerberos::base {

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
    name   => $kerberos::params::client_packages,
    before => File['krb5.conf'],
  }

  file { 'krb5.conf':
    ensure  => file,
    path    => $kerberos::params::krb5_conf_path,
    content => template('kerberos/krb5.conf.erb'),
    mode    => '0644',
    owner   => 0,
    group   => 0,
  }
}
