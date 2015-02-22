# === Type: kerberos::keytab
#
# Creates an empty (!) keytab for later addition of keys using kerberos::ktadd.
# Can force specific owner, group and mode on the file.
#
# === Authors
#
# Michael Weiser <michael.weiser@gmx.de>
#

define kerberos::keytab($keytab = $title,
  $mode = '0400', $owner = 0, $group = 0,
  $replace = false,
) {
  # TODO: Avoid recreation if already existing but do update if keys get to
  # old...
  file { $keytab:
    ensure  => file,
    replace => $replace,
    backup  => false,
    content => inline_template('<%= "\x05\x02" %>'),
    owner   => $owner,
    group   => $group,
    mode    => $mode,
  }
}
