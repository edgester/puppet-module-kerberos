require 'spec_helper_acceptance'

describe 'kerberos' do

  context 'client with defaults' do
    it 'should idempotently run' do
      pp = <<-EOS
        class { 'kerberos':
         client            => true,
         realm             => 'EXAMPLE.ORG',
         domain_realm      => { '.example.org' => 'EXAMPLE.ORG', },
         kdcs              => ['cellserver.example.org'],
         admin_server      => 'cellserver.example.org',
        }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end
  end

  context 'packages installed' do
    describe package('krb5-user') do
      it { should be_installed }
    end
  end

  context 'files provisioned' do
    describe file('/etc/krb5.conf') do
      it { should be_file }
      its(:content) { should match 'default_realm = EXAMPLE.ORG' }
      its(:content) { should match 'kdc = cellserver.example.org' }
      its(:content) { should match 'admin_server = cellserver.example.org' }
      its(:content) { should match '.example.org = EXAMPLE.ORG' }
    end
  end

end
