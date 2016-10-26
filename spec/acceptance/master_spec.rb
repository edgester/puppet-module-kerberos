require 'spec_helper_acceptance'

describe 'kerberos master' do

  context 'client with defaults' do
    it 'should idempotently run' do
      pp = <<-EOS
        class { 'kerberos':
        master                => true,
        realm                 => 'EXAMPLE.ORG',
        kdc_database_password => 'secret',
       }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end
  end

  context 'packages installed' do
    describe package('krb5-kdc') do
      it { should be_installed }
    end

    describe package('krb5-admin-server') do
      it { should be_installed }
    end

    describe package('krb5-config') do
      it { should be_installed }
    end

  end

  context 'files provisioned' do

    describe file('/etc/krb5kdc/kdc.conf') do
      it { should be_file }
      its(:content) { should match 'default_realm = EXAMPLE.ORG' }
      its(:content) { should match 'kdc_ports = 88' }
      its(:content) { should match 'acl_file = /etc/krb5kdc/kadm5.acl' }
    end

    describe file('/etc/krb5kdc/kadm5.acl') do
      it { should be_file }
      its(:content) { should match 'admin@EXAMPLE.ORG' }
    end

    describe file('/etc/krb5.conf') do
      it { should be_file }
    end
  end

end
