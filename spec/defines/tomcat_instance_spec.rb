require "#{File.join(File.dirname(__FILE__),'..','spec_helper.rb')}"

describe 'tomcat::instance', :type => :define do

  let(:title) { 'tomcat_instance' }
  let(:node) { 'rspec.example42.com' }
  let(:params) { {
    :http_port => 8080,
    :control_port => 8480,
  } }
  let (:facts) { {
    :operatingsystem => 'CentOS',
    :osfamily        => 'RedHat',
  } }

  describe 'Test CentOS usage' do
    let (:facts) { {
      :osfamily        => 'RedHat',
      :operatingsystem => 'CentOS',
    } }

    it { should contain_file('instance_tomcat_defaults_tomcat_instance').with_path('/etc/sysconfig/tomcat6-tomcat_instance') }
  end

  describe 'Test RedHat usage' do
    let (:facts) { {
      :operatingsystem => 'RedHat',
      :osfamily        => 'RedHat',
    } }

    it { should contain_file('instance_tomcat_defaults_tomcat_instance').with_path('/etc/sysconfig/tomcat6-tomcat_instance') }
  end

  describe 'Test Debian usage' do
    let (:facts) { {
      :operatingsystem => 'Debian',
      :osfamily        => 'Debian',
    } }

    it { should contain_file('instance_tomcat_defaults_tomcat_instance').with_path('/etc/default/tomcat6-tomcat_instance') }
  end

  describe "Test apache vhost creation" do
    let(:params) { {
      :http_port           => 8080,
      :control_port        => 8480,
      :apache_vhost_create => true,
      :apache_vhost_server_name => 'tomcat.example42.com',
    } }

    describe "Simple" do
      it { should contain_file('/etc/httpd/conf.d/50-tomcat_instance.conf').with_content(/ProxyPass \/tomcat_instance http:\/\/localhost:8080\/tomcat_instance/) }
      it { should contain_file('/etc/httpd/conf.d/50-tomcat_instance.conf').with_content(/ProxyPassReverse \/tomcat_instance http:\/\/localhost:8080\/tomcat_instance/) }
    end

    describe "With manager enabled" do
      let(:params) { {
        :http_port                => 8080,
        :control_port             => 8480,
        :apache_vhost_create      => true,
        :apache_vhost_server_name => 'tomcat.example42.com',
        :manager                  => true,
      } }
      it { should contain_apache__vhost('tomcat_instance').with_server_name('tomcat.example42.com') }
      it { should contain_file('/etc/httpd/conf.d/50-tomcat_instance.conf').with_content(/ProxyPass \/tomcat_instance http:\/\/localhost:8080\/tomcat_instance/) }
      it { should contain_file('/etc/httpd/conf.d/50-tomcat_instance.conf').with_content(/ProxyPassReverse \/tomcat_instance http:\/\/localhost:8080\/tomcat_instance/) }
      it { should contain_file('/etc/httpd/conf.d/50-tomcat_instance.conf').with_content(/ProxyPassReverse \/manager http:\/\/localhost:8080\/manager/) }
      it { should contain_file('/etc/httpd/conf.d/50-tomcat_instance.conf').with_content(/ProxyPassReverse \/manager http:\/\/localhost:8080\/manager/) }
    end
  end

  describe "With modjk" do
    let(:params) { {
      :http_port => 8080,
      :control_port => 8480,
      :ajp_port             => '8042',
      :modjk_workers_file   => '/etc/example/42.cnf',
      :modjk_lbfactor       => '42',
      :modjk_socket_timeout => '4242',
      :modjk_fail_on_status => '424',
      :modjk_domain         => 'example42',
      :modjk_ping_mode      => 'ABC',
    } }

    it { should contain_tomcat__modjk__instance('tomcat_instance').with_workers_file('/etc/example/42.cnf') }
    it { should contain_tomcat__modjk__instance('tomcat_instance').with_lbfactor('42') }
    it { should contain_tomcat__modjk__instance('tomcat_instance').with_socket_timeout('4242') }
    it { should contain_tomcat__modjk__instance('tomcat_instance').with_fail_on_status('424') }
    it { should contain_tomcat__modjk__instance('tomcat_instance').with_domain('example42') }
    it { should contain_tomcat__modjk__instance('tomcat_instance').with_ping_mode('ABC') }
    it { should contain_tomcat__modjk__instance('tomcat_instance').with_ajp_port('8042') }
  end

  describe "Specify tomcat version" do
    let(:params) { {
      :tomcat_version => '8',
      :http_port => 8080,
      :control_port => 8480,
    } }
    let (:facts) { {
      :operatingsystem => 'Debian',
      :osfamily        => 'Debian',
    } }

    it { should contain_service('tomcat-tomcat_instance').with_name('tomcat8-tomcat_instance') }
    it { should contain_file('instance_tomcat_init_tomcat_instance').with_path('/etc/init.d/tomcat8-tomcat_instance') }

  end

  describe 'Test installation with firewalling' do
    let(:facts) { {
      :operatingsystem => 'CentOS',
      :osfamily        => 'RedHat',
      :firewall     => true,
      :firewall_dst => '10.42.42.42',
    } }

    it { should contain_firewall('tomcat_instance-tomcat_instance-tcp-8080').with_port('8080') }
  end

  describe 'Create tomcat instance directory' do
    it { should contain_exec('instance_tomcat_tomcat_instance').with_command('/usr/bin/tomcat-instance-create -p 8080 -c 8480  -w SHUTDOWN -o tomcat -g tomcat -v 6  /var/lib/tomcat6-tomcat_instance') }
    it { should contain_exec('instance_tomcat_tomcat_instance').with_require(/File\[\/usr\/bin\/tomcat-instance-create\]/) }
  end
end

