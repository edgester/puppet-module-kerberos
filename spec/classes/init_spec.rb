require 'spec_helper'
describe 'kerberos' do

  context 'with defaults for all parameters' do
    let(:facts) { {:osfamily => 'Debian'} }
    it { should contain_class('kerberos') }
    it { should_not contain_class('kerberos::client') }
    it { should_not contain_class('kerberos::kdc::master') }
    it { is_expected.to compile.with_all_deps }
  end

  context 'with client=true' do
    let(:facts) { {:osfamily => 'Debian'} }
    let(:params) { { :client => true } }
    it { should contain_class('kerberos') }
    it { should contain_class('kerberos::client') }
    it { should_not contain_class('kerberos::kdc::master') }
    it { is_expected.to compile.with_all_deps }
  end

end
