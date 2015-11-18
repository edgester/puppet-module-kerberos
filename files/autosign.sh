#!/bin/bash

# This autosign script somewhat hackishly creates certificates for puppet
# clients directly, circumventing Puppet's internal CA's constraints. This
# enables it to put custom extensions for PKINIT into it.

# Unfortunately this also disables interactive review by the puppet
# administrator. That is why it implements a check for a pre-shared key being
# present in the certificate request.

# Implements MIT Kerberos PKINIT certificate generation as per
# http://web.mit.edu/kerberos/krb5-1.12/doc/admin/pkinit.html.
# Implements autosigning as per
# https://docs.puppetlabs.com/puppet/3.7/reference/ssl_autosign.html#policy-based-autosigning
# and
# https://docs.puppetlabs.com/puppet/3.7/reference/ssl_attributes_extensions.html#custom-attributes-transient-csr-data.

# BE AWARE that this is not a finished product. It is meant as a starting point
# for implementing your own autosign policy based on your own node
# classification system. See markers "NODE CLASSIFICATION" and "SIGNING POLICY"
# below.

# Also note that this script uses trocla for generating and storing the
# pre-shared key used as a node authenticator in the certficate signing
# request. This again is just an example of how it can be done and depending on
# your site's preferences and infrastructure can be implemented differently.

# The important thing is to get the pre-shared key onto the node in a somewhat
# secure manner since it completely replaces the manual key fingerprint review
# by the Puppet administrator.

# To use, set option autosign in puppet.conf on the master to the path to this
# script and install a csr_attributes.yaml on each agent containing e.g.:
#
# custom_attributes:
#   challengePassword: '<pre-shared key, optimally generated specifically for this machine, e.g. using trocla>'

# five years just as Puppet
days=1825

cn="$1"
puppetetc=/etc/puppet
hieradir="$puppetetc"/hieradata
hieranode="$hieradir"/node/"$cn".yaml
troclarc="$puppetetc"/troclarc.yaml
troclaid=hiera/node/"$cn"/puppet_psk

# SIGNING POLICY: First of all check if we know that node at all.
if ! [ -f "$hieranode" ] ; then
	echo "Unknown node $cn"
	exit 1
fi

puppetca=/var/lib/puppet/ssl/ca
cakey="$puppetca"/ca_key.pem
cacert="$puppetca"/ca_crt.pem
casrl="$puppetca"/serial
puppetcert="$puppetca"/signed/"$cn".pem
puppetcsr="$puppetca"/requests/"$cn".pem

# Determine realm from config. We assume kerberos::realm: '<realm>' syntax and
# split at the single quote.
realm=$(grep "^kerberos::realm:" "$hieradir"/common.yaml | \
	cut -d\' -f2)

d=$(mktemp -d)
csr="$d"/csr.pem
extfile="$d"/extensions

# acquire CSR from stdin
cat - > "$csr"

# SIGNING POLICY: extract the pre-shared key from the csr and check it
# 1.3.6.1.4.1.34380.1.1.4 == pp_preshared_key
# challengePassword
cpw=$(openssl req -noout -text -in "$csr" | \
	grep "challengePassword[ ]*:" 2>/dev/null | \
	sed -e "s,^[[:space:]]*challengePassword[[:space:]]*:,,")
if [ -z "$cpw" ] ; then
	echo "Challenge password missing from certificate request of $cn"
	exit 1
fi

# retrieve PSK from trocla
psk=$(trocla -c "$troclarc" get "$troclaid" plain)
if [ "$cpw" != "$psk" ] ; then
	echo "Invalid challenge password in certificate request of $cn"
	exit 1
fi

# TODO: Duplicate additional Puppet CA constraints such as acceptable key
# usages and subjectAltNames. For now we implicitly implement them by not
# copying anything from the request which somewhat limits flexibility.

# policy decision done: we're satisfied that we know this client and it has
# provided the correct pre-shared key in the CSR

# signing:
# - we will not copy any extensions, subjectAltNames or key usages from the
#   request
eku="TLS Web Server Authentication,TLS Web Client Authentication"
san="DNS:$cn"
pkinit_ext_msg=""
pkinit_ext_msg_sep=""

# NODE CLASSIFICATION: We assume a /etc/puppet/hieradata/node/$fqdn.yaml
# containing some kind of node classification array with role names such as
# role::kerberos::client and role::kerberos::server. Implement your own
# classification system here as needed.
if grep -- '^[[:space:]]*- role::kerberos::client' "$hieranode" >/dev/null 2>/dev/null ; then
	eku="${eku},1.3.6.1.5.2.3.4"
	san="${san},otherName:1.3.6.1.5.2.2;SEQUENCE:princ_name"
	pkinit_ext_msg="$pkinit_ext_msg${pkinit_ext_msg_sep}PKINIT client"
	pkinit_ext_msg_sep=" and "
fi

if grep -- '^[[:space:]]*- role::kerberos::server' "$hieranode" >/dev/null 2>/dev/null ; then
	eku="${eku},1.3.6.1.5.2.3.5"
	san="${san},otherName:1.3.6.1.5.2.2;SEQUENCE:kdc_princ_name"
	pkinit_ext_msg="$pkinit_ext_msg${pkinit_ext_msg_sep}PKINIT KDC"
	pkinit_ext_msg_sep=" and "
fi

[ -z "$pkinit_ext_msg" ] || pkinit_ext_msg=" with extensions $pkinit_ext_msg"

cat << EOF >> "$extfile"
[puppet_cert]
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyAgreement
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
extendedKeyUsage=$eku
subjectAltName=$san

[kdc_princ_name]
realm=EXP:0,GeneralString:$realm
principal_name=EXP:1,SEQUENCE:kdc_principal_seq

[kdc_principal_seq]
name_type=EXP:0,INTEGER:1
name_string=EXP:1,SEQUENCE:kdc_principals

[kdc_principals]
princ1=GeneralString:krbtgt
princ2=GeneralString:$realm

[princ_name]
realm=EXP:0,GeneralString:$realm
principal_name=EXP:1,SEQUENCE:principal_seq

[principal_seq]
name_type=EXP:0,INTEGER:1
name_string=EXP:1,SEQUENCE:principals

[principals]
princ1=GeneralString:$cn
EOF

if openssl x509 \
	-CAkey "$cakey" -CA "$cacert" -CAserial "$casrl" \
	-req -in "$csr" \
	-extensions puppet_cert -extfile "$extfile" \
	-days "$days" -out "$puppetcert" ; then
	echo "autosigned csr for $cn$pkinit_ext_msg"
else
	echo "openssl failure autosigning csr of $cn"
fi

rm -rf "$d"
rm -f "$puppetcsr"

# always tell puppet not to sign because we just did
exit 1
