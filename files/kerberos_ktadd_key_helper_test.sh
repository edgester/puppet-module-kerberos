#!/bin/bash

d=$(mktemp -d)
k="$d"/t.keytab
p1=a/b@C.D
p2=e/f@C.D

hwclock --systohc

ktadd() {
	date="$1"
	kvno="$2"
	date -s "$1"

	cat << EOF | ktutil
addent -password -p $p1 -k $kvno -e arcfour-hmac
a
addent -password -p $p2 -k $kvno -e arcfour-hmac
a
wkt $k
quit
EOF
}

ktadd "90 days ago" 1
ktadd "15 days" 2
ktadd "15 days" 3
ktadd "15 days" 4
ktadd "15 days" 5
ktadd "15 days" 6

hwclock --hctosys

# check state of keytab
while read expected_rc princ max_key_age opts ; do
	./kerberos_ktadd_key_helper.sh -n $opts "$k" $princ $max_key_age
	rc="$?"
	if [ "$rc" != "$expected_rc" ] ; then
		echo "Unexpected rc $rc vs. $expected_rc on test $k:$princ:$max_key_age:$opts"
		exit 1
	fi
done <<EOF
0 $p1 100
0 $p1 100 -c
1 $p1 100 -o 10
2 $p1 10
2 $p1 10 -c
2 $p1 10 -o 10
EOF
rc="$?"

rm -rf "$d"
exit "$rc"
