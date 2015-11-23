# == Class: kerberos
#
# Base class for the module. Provides parameter defaulting from
# kerberos::params with override via hiera lookups.
#
# === Parameters
#
# Paths:
#
# $krb5_conf_path:
#   Path to the client configuration file.
#
# $kdc_conf_path = $kerberos::params::kdc_conf_path,
#   Path to the main KDC configuration file.
#
# $kadm5_acl_path = $kerberos::params::kadm5_acl_path,
#   Path to the admin service ACL file.
#
# $kpropd_acl_path = $kerberos::params::kpropd_acl_path,
#   Path to the database replication daemon ACL file.
#
# $kprop_cron_path = $kerberos::params::kprop_cron_path,
#   Path to the database replication push cron script.
#
# $kdb5_util_path = $kerberos::params::kdb5_util_path,
#   Path of kdb5_util used for creating databases.
#
# $kprop_path = $kerberos::params::kprop_path,
#   Path to the kprop utility.
#
# Settings in files:
#
# krb5.conf
# $realm:
#   The Kerberos realm (e.g. 'EXAMPLE.COM')
#
# $domain_realm
#   Hash of domain to realm mappings.
#
# $kdcs
#   Array of KDCs to configure.
#
# $master_kdc
#   The master KDC to configure (used for password changes).
#
# $admin_server
#   The admin service to use.
#
# $allow_weak_crypto
#   Re-enable Single-DES.
#
# $forwardable
#   Request forwardable tickets by default.
#
# $proxiable
#   Request proxiable tickets by default.
#
# $pkinit_anchors
#   Path to CA certificate to use for PKINIT.
#
# kdc.conf
# $kdc_ports
#   Ports to have the KDC listen on.
#
# $kdc_database_path
#   Path to the principal database.
#
# $kdc_stash_path
#   Path to key stash.
#
# $kdc_max_life
#   Maximum ticket lifetime allowed by the KDC.
#
# $kdc_max_renewable_life
#   Maximum renewable lifetime allowed by the KDC.
#
# $kdc_master_key_type
#   The key type to use to encrypt the principal database.
#
# $kdc_supported_enctypes
#   List of encryption types supported by the KDC.
#
# $kdc_pkinit_identity
#   Certificate and private key to use for PKINIT at the KDC. Format: <path to
#   cert>,<path to key>. FILE: is prepended automatically if beginning with a
#   slash.
#
# $kdc_logfile
# no kadm5.conf, so it's in kdc.conf
# $kadmind_logfile
#   Valid values for $kdc_logfile and $kadmind_logfile include:
#   FILE:/var/log/kdc.log
#   CONSOLE
#   SYSLOG:INFO:DAEMON
#   DEVICE=/dev/tty04
#
# Yet to try:
# $kdc_iprop_port
#   Port to use for incremental replication (listened on by the kpropd on the
#   slave and connected to by the master?).
#
# $kdc_iprop_logfile
#   Logfile to use for incremental replication (on the master?).
#
# $kprop_cron_hour
# $kprop_cron_minute
#   When to run the kprop cron job.
#
# $kprop_principal
# $kprop_keytab
#   Principal and keytab to be used by kprop for authenticating to kpropd on
#   the slave.
#
# $kpropd_iprop_resync_timeout
#   ?
#
# $kpropd_principal
# $kpropd_keytab
#   What principal and keytab kpropd should authentication for and verify it
#   with.
#
# $kpropd_master_principal
#   What principals to allow to update the database on this slave.
#
# $kdc_principals
# $kdc_trusted_realms
#   Principals and realm trusts to be created on the master.
#
# $kadmind_enable
#   Whether to actually enable kadmind.
#
# $kadmind_acls
#   ACLs for for the admin service.
#
# $kdc_slaves
#   List of slaves of this KDC (may be a slave itself).
#
# $host_ticket_cache_ccname
# $host_ticket_cache_service
# $host_ticket_cache_principal
#   When creating a ticket cache for use by kadmin use these parameters.
#
# $ktadd_max_key_age
#   Default for maximum age of keys in keytab files in days. If greater than
#   zero, a cron job is installed that regularly checks for timestamps of keys
#   for principals and runs the equivalent of k5srvutil change & delold.
#
# $ktadd_client_only
#   Whether to preserve only the current set of keys or the last set as well.
#   The latter is needed for services to continue to function while tickets
#   using the old keys are still in use.
#
# $ktadd_cronjob_hour
# $ktadd_cronjob_minute
#   When to run the key age check cron job.
#
# $ktadd_key_helper
#   The command to use when checking and possibly updating keys in keytabs.
#
# $ktadd_check_helper
#   Base name of helper scripts to generate for checking if keys are current.
#   Defaults to undef, meaning that no scripts will be created. Set to e.g.
#   /usr/local/bin/kerberos_ktadd_check to enable.
#
# $pkinit_packages
# $client_packages
# $kdc_server_package
# $kadmin_server_package
#   Package names.
#
# $kdc_service_name
# $kadmin_service_name
# $kpropd_service_name
#   Service names.
#
# === References
#
# [1] http://web.mit.edu/kerberos/krb5-1.6/krb5-1.6.3/doc/krb5-install.html#Create-the-Database
#
# [2] http://web.mit.edu/kerberos/krb5-1.6/krb5-1.6.3/doc/krb5-install.html#Add-Administrators-to-the-Acl-File
#
# [3] http://web.mit.edu/kerberos/krb5-1.6/krb5-1.6.3/doc/krb5-install.html#Create-a-kadmind-Keytab-_0028optional_0029
#
# === Authors
#
# Jason Edgecombe <jason@rampaginggeek.com>
# Additions by Michael Weiser <michael.weiser@gmx.de>
#
# === Copyright
#
# Copyright 2013 Jason Edgecombe, unless otherwise noted.
#
class kerberos(
  # roles
  $client = false,
  $master = false,
  $slave = false,

  # paths to configuration files
  $krb5_conf_path = $kerberos::params::krb5_conf_path,
  $kdc_conf_path = $kerberos::params::kdc_conf_path,
  $kadm5_acl_path = $kerberos::params::kadm5_acl_path,
  $kpropd_acl_path = $kerberos::params::kpropd_acl_path,
  $kprop_cron_path = $kerberos::params::kprop_cron_path,
  $kdb5_util_path = $kerberos::params::kdb5_util_path,
  $kprop_path = $kerberos::params::kprop_path,

  # settings in files
  $realm = 'EXAMPLE.COM',
  $domain_realm = {},
  $kdcs = [],
  $master_kdc = undef,
  $admin_server = undef,
  $allow_weak_crypto = false,
  $forwardable = true,
  $proxiable = true,
  $pkinit_anchors = undef,

  $kdc_ports = '88',
  $kdc_database_path = $kerberos::params::kdc_database_path,
  $kdc_database_password = undef,
  $kdc_stash_path = $kerberos::params::kdc_stash_path,
  $kdc_max_life = 10 * 60 * 60, # '0d 10h 0m 0s'
  $kdc_max_renewable_life = '7d 0h 0m 0s',
  $kdc_master_key_type = 'aes256-cts',
  $kdc_supported_enctypes = [ 'aes256-cts:normal',
    'arcfour-hmac:normal',
    'des3-hmac-sha1:normal' ],
  $kdc_pkinit_identity = undef,
  $kdc_logfile = $kerberos::params::kdc_logfile,
  $kdc_iprop_port = undef,
  $kdc_iprop_logfile = undef,

  # no kadm5.conf, so it's in kdc.conf
  $kadmind_logfile = $kerberos::params::kadmind_logfile,

  $kprop_cron_hour = '*',
  $kprop_cron_minute = '*/5',
  $kprop_principal = "host/${fqdn}",
  $kprop_keytab = '/etc/krb5.keytab',

  $kpropd_iprop_resync_timeout = undef,
  $kpropd_principal = "host/${fqdn}",
  $kpropd_keytab = '/etc/krb5.keytab',
  $kpropd_master_principal = undef,

  # settings to be implemented via logic
  $kdc_principals = {},
  $kdc_trusted_realms = {},

  $kadmind_enable = true,
  $kadmind_acls = { "*/admin@${realm}" => '*' },

  $host_ticket_cache_ccname = '/var/lib/puppet/krb5cc.puppet',
  $host_ticket_cache_service = 'kadmin/admin',
  $host_ticket_cache_principal = $fqdn,

  $ktadd_max_key_age = 60, # days
  $ktadd_client_only = false,
  $ktadd_cronjob_hour = '*',
  $ktadd_cronjob_minute = '2',
  $ktadd_key_helper = '/usr/local/bin/kerberos_ktadd_key_helper',
  $ktadd_check_helper = undef,

  $pkinit_cert = $kerberos::params::pkinit_cert,
  $pkinit_key  = $kerberos::params::pkinit_key,

  $kdc_slaves = undef,

  # packages
  $pkinit_packages = $kerberos::params::pkinit_packages,
  $client_packages = $kerberos::params::client_packages,
  $kdc_server_package = $kerberos::params::kdc_server_package,
  $kadmin_server_package = $kerberos::params::kadmin_server_package,

  # service names
  $kdc_service_name = $kerberos::params::kdc_service_name,
  $kadmin_service_name = $kerberos::params::kadmin_service_name,
  $kpropd_service_name = $kerberos::params::kpropd_service_name,
) inherits kerberos::params {
  $kpropd_master_principal_cfg = $kpropd_master_principal ? {
    default => $kpropd_master_principal,
    undef => "host/${master_kdc}@${realm}",
  }

  $kdc_logfile_cfg = $kdc_logfile ? {
    undef => undef,
    default => regsubst($kdc_logfile, '^/', 'FILE:/')
  }

  $kadmind_logfile_cfg = $kadmind_logfile ? {
    undef => undef,
    default => regsubst($kadmind_logfile, '^/', 'FILE:/')
  }

  $pkinit_anchors_cfg = $pkinit_anchors ? {
    undef => undef,
    default => regsubst($pkinit_anchors, '^/', 'FILE:/')
  }

  $kdc_pkinit_identity_cfg = $kdc_pkinit_identity ? {
    undef => undef,
    default => regsubst($kdc_pkinit_identity, '^/', 'FILE:/')
  }

  if $client {
    include kerberos::client
  }

  if $master {
    include kerberos::kdc::master
  }

  if $slave {
    include kerberos::kdc::slave
  }
}
