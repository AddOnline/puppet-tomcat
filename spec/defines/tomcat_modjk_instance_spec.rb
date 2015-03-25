require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'tomcat::modjk::instance', :type => :define do

  let(:title) { 'my_worker42' }
  let(:node) { 'rspec.example42.com' }

  let(:params) {{
    :workers_file => '/etc/worker42.properties',
    :ajp_port     => '8042',
  }}

  describe "Default usage" do
    it { should contain_concat__fragment('tomcat_modjk_instance_my_worker42').with_target('/etc/worker42.properties') }
    it { should contain_concat__fragment('tomcat_modjk_instance_my_worker42').with_content(/worker.my_worker42.port=8042/) }
  end
end
