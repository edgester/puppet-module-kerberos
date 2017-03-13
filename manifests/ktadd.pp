# === Type: kerberos::ktadd
#
# Adds a kerberos key to a keytab. Supports use of kadmin.local or kadmin. The
# latter supports use of a ticket cache or a keytab file.
#
# === Authors
#
# Michael Weiser <michael.weiser@gmx.de>
#

# infer principal and keytab file names from title if not given explicitly,
# syntax: <keytab>@<principal_possibly_containing_more_@s>
define kerberos::ktadd(
  $keytab = regsubst($title, '@.*$', ''),
  $principal = regsubst($title, '^[^@]*@', ''),
  $local = true, $reexport = false,
  $kadmin_ccache = undef, $kadmin_keytab = undef,
  $kadmin_tries = undef, $kadmin_try_sleep = undef,
  $kadmin_server_package = $kerberos::kadmin_server_package,
  $client_packages = $kerberos::client_packages,
  $krb5_conf_path = $kerberos::krb5_conf_path,
  $realm = $kerberos::realm,
  $max_key_age = $kerberos::ktadd_max_key_age,
  $client_only = $kerberos::ktadd_client_only,
  $keytab_owner = undef,
  $cronjob_hour = $kerberos::ktadd_cronjob_hour,
  $cronjob_minute = $kerberos::ktadd_cronjob_minute,
  $kdc_max_life = $kerberos::kdc_max_life,
  $ktadd_key_helper = $kerberos::ktadd_key_helper,
  $ktadd_check_helper = $kerberos::ktadd_check_helper,
) {
  $ktadd = "ktadd_${keytab}_${principal}"
  if $local {
    $kadmin = 'kadmin.local'
    Package[$kadmin_server_package] -> Exec[$ktadd]
    Exec['create_krb5kdc_principal'] -> Exec[$ktadd]
  } else {
    $kadmin = 'kadmin'

    $ccache_par = $kadmin_ccache ? {
      undef   => '',
      default => "-c '${kadmin_ccache}'"
    }

    $keytab_par = $kadmin_keytab ? {
      undef   => '',
      default => "-k '${kadmin_keytab}'"
    }

    Package[$client_packages] -> Exec[$ktadd]
    File['krb5.conf'] -> Exec[$ktadd]
  }

  if $reexport {
    $unless = undef
  } else {
    $unless = "klist -k '${keytab}' | grep ' ${principal}@${realm}'"
  }

  $cmd = "ktadd -k ${keytab} ${principal}"
  exec { $ktadd:
    command     => "${kadmin} ${ccache_par} ${keytab_par} -q '${cmd}'",
    unless      => $unless,
    path        => [ '/bin', '/usr/bin', '/usr/bin', '/usr/sbin' ],
    environment => "KRB5_CONFIG=${krb5_conf_path}",
    require     => File[$keytab],
    tries       => $kadmin_tries,
    try_sleep   => $kadmin_try_sleep,
  }

  # calculate some values we need later on
  $ktcron_job = "${ktadd} key change cron job"
  $ktcheck_suffix = regsubst("${keytab}_${principal}", '[\./@]', '_', 'G')
  $ktcheck = "${ktadd_check_helper}${ktcheck_suffix}"

  # potentially install a key change cron job for the newly added principal
  if $max_key_age > 0 {
    if is_integer($kdc_max_life) {
      if $client_only {
        # clean out all old keys since a client only needs the current set
        $delold = '-c'
        $delold_ktc = ''
      } else {
        # remove old keys when the current set got older than the maximum
        # allowed ticket lifetime plus an hour for safety
        $old_key_preserve_window = $kdc_max_life + 3600
        $delold = "-o '${old_key_preserve_window}'"

        # be less strict about key deletion when checking to avoid false
        # positives and flapping
        $old_key_preserve_window_ktc = $kdc_max_life + 7200
        $delold_ktc = "-o '${old_key_preserve_window_ktc}'"
      }

      # be less strict about key expiry when checking to avoid false
      # positives and flapping
      $max_key_age_ktc = $max_key_age + 1
    } else {
      warning('Please specify kdc_max_life in seconds as integer.')
      warning('Otherwise, maximum key age plausibility checks for keytab')
      warning('entries can not be implemented and old keys have to be left')
      warning('in the keytab longer than necessary.')

      if $client_only {
        # clean out all old keys since a client only needs the current set
        $delold = '-c'
      } else {
        # the key helper script defaults to leaving one set of old keys in
        # until the next key update
        $delold = ''
      }
      $delold_ktc = ''
    }

    # construct helper commands
    $ktadd_o = "'${keytab}' '${principal}@${realm}'"
    $ktcron_cmd = "${ktadd_key_helper} ${delold} ${ktadd_o} '${max_key_age}'"
    $ktcheck_cmd = "${ktadd_key_helper} -n ${delold_ktc} ${ktadd_o} '${max_key_age_ktc}'"

    if !defined(File[$ktadd_key_helper]) {
      # install helper script for key updates and age checks
      file { $ktadd_key_helper:
        mode    => '0755',
        owner   => 0,
        group   => 0,
        source  => 'puppet:///modules/kerberos/kerberos_ktadd_key_helper.sh',
        # uses klist to list and kadmin to change keys
        require => Package[$client_packages],
      }
    }

    # install the actual key age check and update cron job
    cron { $ktcron_job:
      ensure  => present,
      command => $ktcron_cmd,
      user    => $keytab_owner,
      hour    => $cronjob_hour,
      minute  => $cronjob_minute,
      require => [File[$keytab], File[$ktadd_key_helper]],
    }

    # optionally install a helper script that can be used to check if the keys
    # are up to date
    if $ktadd_check_helper {
      file { $ktcheck:
        mode    => '0755',
        owner   => 0,
        group   => 0,
        content => "#\$!/bin/bash\nexec ${ktcheck_cmd}\n",
        # uses klist to list and kadmin to change keys
        require => File[$ktadd_key_helper],
      }
    }
  } else {
    # remove stuff we don't need. Can't remove the key helper script, because
    # that's shared amongst all ktadd resource instances.
    cron { $ktcron_job:
      ensure => absent,
      user   => $keytab_owner,
    }

    if $ktadd_check_helper {
      file { $ktcheck:
        ensure => absent,
      }
    }
  }
}
