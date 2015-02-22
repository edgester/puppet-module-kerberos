require 'spec_helper'
describe 'kerberos' do
  
  let(:facts) { {:operatingsystem => 'Debian'} }
  context 'with defaults for all parameters' do
    it { should contain_class('kerberos') }
  end
end
