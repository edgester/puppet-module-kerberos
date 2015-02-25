# A puppet module for managing MIT Kerberos clients and servers  [![Build Status](https://travis-ci.org/edgester/puppet-module-kerberos.svg?branch=master)](https://travis-ci.org/edgester/puppet-module-kerberos)

License
-------
BSD

Contact
-------

jason@rampaginggeek.com

Support
-------
Please log tickets and issues at our [Projects site](https://github.com/edgester/puppet-kerberos)

Example Use
-----------
```
# Kerberos server (kdc and kadmin)
class {'kerberos':
  master                => true,
  realm                 => 'EXAMPLE.ORG',
  kdc_database_password => 'secret',
}

# kerberos client
class {'kerberos':
  client            => true,
  realm             => 'EXAMPLE.ORG',
  domain_realm      => { '.example.org' => 'EXAMPLE.ORG', },
  kdcs              => ['cellserver.example.org'],
  admin_server      => 'cellserver.example.org',
  allow_weak_crypto => true,
}
```

Hiera Usage
-----------

Define all the main class parameters you'd like to change like this:

    kerberos::realm: 'EXAMPLE.ORG'
    kerberos::kdcs:
      - 'cellserver.example.org'

Forget about `client => true`. Just include or hiera_include() any of the
following classes:

    kerberos::client
    kerberos::kdc::master
    kerberos::kdc::slave


It is best to store passwords in Hiera; that way, you can have a set of test
credentials, and a different set of credentials for production servers.  For
example, in debug environments, you might use *realmone.local* and *realmtwo.local*
instead of *realmone.com* and *realmtwo.com*, which of course would cause puppet
to pull your configuration from different .yaml files.  Debug configuration
could be checked in to the repository, and production values could be stored
in a more secure location.


###kdc1.realmone.com.yaml:
```
  ---
  kerberos_principals:
    user1:
      password: secretsecret
```


###kdc2.realmtwo.com.yaml:
```
  ---
  kerberos_principals:
    user2:
      password: p4ssw0rd!
```


###production.yaml:
```
  ---
  kerberos::kdc_database_password: verylongsecurerandomlyproducedpassword

  trusted_realms:
    realms:
      - REALMONE.COM
      - REALMTWO.COM
    password: differentverylongsecurerandomlyproducedpassword
```
