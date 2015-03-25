require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'tomcat::mod_jk', :type => :define do

  let(:title) { '/etc/worker/example/42.cnf' }
  let(:node) { 'rspec.example42.com' }

  describe "Default usage" do
    it { should contain_concat('/etc/worker/example/42.cnf') }
    it { should contain_concat__fragment('/etc/worker/example/42.cnf-header').with_target('/etc/worker/example/42.cnf') }
  end
end
