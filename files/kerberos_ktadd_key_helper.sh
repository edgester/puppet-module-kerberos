#!/bin/sh

# Due to the way we trick klist into displaying timestamps as seconds since
# epoch, this script currently is Linux- and MIT-Kerberos-only. The
# localedef-part was also tested on OS X but not the whole script.

usage() {
	cat << EOF
$0 [-c] [-o <seconds>] <keytab> <principal> <max key age>

	-c	client only: Remove all old keys after getting new ones
	-o <seconds>	Remove all old keys if the current ones are older
		than the number of seconds given as parameter. Default is
		to leave one set of old keys in the keytab until the next
		key change.
	-n	nagios-compatible dry-run mode

	<keytab>	keytab file to update
	<principal>	principal to update
	<max key age>	maximum age of keys before keys are updated
EOF
	exit 1
}

client_only=0
old_key_preserve_window=0
dryrun=0
while getopts "cno:" OPT ; do
	case "$OPT" in
		c) client_only=1 ;;
		n) dryrun=1 ;;
		o) old_key_preserve_window="$OPTARG" ;;
		*) usage ;;
	esac
done

# shift away all the options parsed by getops and check for the required number
# of positional arguments
for i in `seq 2 $OPTIND` ; do shift ; done
[ "$#" != "3" ] && usage

keytab="$1"
princ="$2"
max_key_age="$3"

# Make a temporary directory in which to compile a custom locale.
lp=$(mktemp -d 2>/dev/null)
if [ -z "$lp" ] ; then
	echo "Error creating temporary directory using mktemp" >&2
	exit 2
fi

# MIT's klist -t tries to fit the date and time into a fixed-length buffer for
# aligned printing of the table. For that it tries a number of strftime format
# strings, the first one being %c - the current locale's appropriate date/time
# representation. This allows us to override how timestamps are dislpayed. So
# create a custom locale definition that makes %c print just the seconds since
# epoch.
cat <<EOF | LANG=C localedef -c $lp/epoch >/dev/null 2>&1
LC_TIME
d_t_fmt "%s"
END LC_TIME
EOF

# Unfortunately, since we're using a very sparse locale definiton, localedef
# will always print warnings and exit with an error although it successfully
# compiles the locale. So we check if the file we really need was created.
# Beware: There are cases where localedef will create it but will not put our
# d_t_fmt into it. This will be caught by the next check.
if ! [ -f "$lp/epoch/LC_TIME" ] ; then
	echo "Error compiling custom locale" >&2
	exit 2
fi

# Print the keytab contents using our epoch custom locale, filter out entries not
# listing a kvno, seconds since epoch and our principal, numerically sort by
# timestamp and get the most current one.
# glibc: LOCPATH, OS X (/ FreeBSD?): PATH_LOCALE
ts=$(LOCPATH="$lp" PATH_LOCALE="$lp" LANG=epoch klist -tk "$keytab" | \
	grep "^[[:space:]]*[0-9]\+[[:space:]]\+[0-9]\+[[:space:]]\+$princ$" | \
	awk '{ print $2 }' | \
	sort -n | \
	tail -n 1)

# Custom locale no longer necessary
rm -rf "$lp"

# Did we get a timestamp and is it really, really, really just a single number
# which might suggest, it's seconds since epoch?
if ! echo "$ts" | grep "^[0-9]\+$" >/dev/null 2>&1 ; then
	echo "Error determining timestamp of most current set of keys" >&2
	exit 2
fi

# Get seconds since epoch for the date our keys are to expire (maximum key
# age).
deadline=$(date --date "$max_key_age days ago" +"%s")
if [ -z "$deadline" ] ; then
	echo "Error determining timestamp of key change deadline"
	exit 2
fi

# Maybe it's not yet time to get a new set of keys but it might be time to
# throw away a preserved set of old keys.
preserve_deadline=

if [ "$old_key_preserve_window" != "0" ] ; then
	# check if there's actually a set of old keys for that principal in the
	# keytab - tail -n +2 will only return something if there's more than
	# one line
	if [ -n "$(klist -k "$keytab" | \
		grep "^[[:space:]]*[0-9]\+[[:space:]]\+$princ$" | \
		awk '{ print $1 }' | \
		sort -un | \
		tail -n +2)" ] ; then
		preserve_deadline=$(date --date "$old_key_preserve_window seconds ago" +"%s")
		if [ -z "$preserve_deadline" ] ; then
			echo "Error determining timestamp of key preservation window"
			exit 2
		fi
	fi
fi

if [ "$dryrun" = "1" ] ; then
	if [ "$ts" -le "$deadline" ] ; then
		echo "Keys for $princ in keytab $keytab are expired."
		exit 2
	fi

	if [ -n "$preserve_deadline" ] && [ "$ts" -le "$preserve_deadline" ] ; then
		echo "Old set of keys $princ in keytab $keytab should be removed."
		exit 1
	fi

	echo "Kerberos keys for $princ in keytab $keytab are current."
	exit 0
fi

delold() {
	do_keytab="$1"
	do_princ="$2"

	# Stolen from MIT Kerberos' k5srvutil: Remove all but the last set of
	# keys from the keytab.
	if ! kadmin -k -t "$do_keytab" -p "$do_princ" \
		-q "ktrem -k $do_keytab $do_princ old" ; then
		echo "Error removing old keys for $do_princ from keytab $do_keytab" >&2
		exit 2
	fi
}

# Are the most current keys in the keytab older than our deadline?
if [ "$ts" -le "$deadline" ] ; then
	# If this keytab is used for services as well as clients, remove old keys
	# before getting new ones so that the last set of keys remains after the
	# update.
	[ "$client_only" = "0" ] && \
		[ "$old_key_preserve_window" = "0" ] && \
		delold "$keytab" "$princ"

	# Stolen from MIT Kerberos' k5srvutil: Get new set of keys.
	if ! kadmin -k -t "$keytab" -p "$princ" \
		-q "ktadd -k $keytab $princ" ; then
		echo "Error getting new set of keys for $princ and keytab $keytab"
		exit 2
	fi

	# If this keytab is used for clients only, remove old keys after getting new
	# ones so that only the current set remains.
	[ "$client_only" = "0" ] || \
		delold "$keytab" "$princ"
else
	if [ -n "$preserve_deadline" ] && [ "$ts" -le "$preserve_deadline" ] ; then
		# Last set of keys was written to the keytab more than
		# $old_key_preserve_window seconds ago. That means, we can
		# assume that all tickets using those keys are now expired. So
		# we can trash all old keys.
		delold "$keytab" "$princ"
	fi
fi

exit 0
