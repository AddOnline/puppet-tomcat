# Define: tomcat::instance
#
#  [*tomcat_version*]
#   By default we use the distro tomcat version but if you have many installed
#   version you would need to set the tomcat version you want for each
#   instance.
#   Default: ''
#
define tomcat::instance (

  $http_port,
  $control_port,
  $ajp_port                     = '',
  $instance_autorestart         = true,
  $service_enable               = true,
  $service_ensure               = 'running',
  $service_hasrestart           = true,

  $dirmode                      = '0755',
  $filemode                     = '0644',
  $owner                        = '',
  $group                        = '',

  $magicword                    = 'SHUTDOWN',

  $runtime_dir                  = '',

  $java_opts                    = '-Djava.awt.headless=true -Xmx128m  -XX:+UseConcMarkSweepGC',
  $catalina_opts                = '',
  $java_home                    = '',

  $catalina_properties_template = '',
  $logging_properties_template  = '',
  $init_template                = '',
  $systemd_template             = '',
  $init_defaults_template       = '',
  $startup_sh_template          = '',
  $shutdown_sh_template         = '',
  $setenv_sh_template           = '',
  $params_template              = '',
  $create_instance_cmd_template = '',
  $create_instance_cmd_exec     = '',
  $server_xml_template          = '',
  $http_connector_options       = '',
  $ajp_connector_options        = '',
  $context_xml_template         = '',
  $tomcat_users_xml_template    = '',
  $web_xml_template             = '',
  $manager_xml_template         = 'tomcat/instance/manager.xml.erb',

  $tomcat_version               = '',
  $tomcatuser                   = '',
  $tomcatpassword               = '',

  $puppi                        = false,
  $monitor                      = false,
  $monitor_tool                 = $::monitor_tool,

  $manager                      = false,

  $modjk_workers_file           = '',
  $modjk_lbfactor               = '1',
  $modjk_socket_timeout         = '0',
  $modjk_fail_on_status         = '0',
  $modjk_domain                 = '',
  $modjk_ping_mode              = '',

  $apache_vhost_create          = false,
  $apache_vhost_template        = 'tomcat/apache/vhost.conf.erb',
  $apache_vhost_server_name     = '',
  $apache_vhost_docroot         = undef,
  $apache_vhost_proxy_alias     = '',
  $apache_vhost_context         = ''

  ) {

  require tomcat::params

  $ensure_real = $service_ensure ? {
    'undef' => undef,
    default => $service_ensure,
  }

  $bool_instance_autorestart=any2bool($instance_autorestart)
  $bool_manager=any2bool($manager)

  $manage_tomcat_version = $tomcat_version ? {
    ''      => $tomcat::params::real_version,
    default => $tomcat_version,
  }

  # Application name, required
  $instance_name = $name

  # Application owner, by default the same instance name
  $instance_owner = $owner ? {
    ''      => $tomcat::process_user,
    default => $owner,
  }

  # Application group, by default the same instance name
  $instance_group = $group ? {
    ''      => $tomcat::process_user,
    default => $group,
  }

  # CATALINA BASE
  $instance_path = "/var/lib/tomcat${manage_tomcat_version}-${instance_name}"

  # Startup script
  $instance_startup = "${instance_path}/bin/startup.sh"

  # Shutdown script
  $instance_shutdown = "${instance_path}/bin/shutdown.sh"

  $instance_init_template = $init_template ? {
    ''      => "tomcat/instance/init${manage_tomcat_version}-${::osfamily}.erb",
    default => $init_template
  }

  $instance_tomcat_init_path = $::osfamily ? {
    /(?i:CentOS|RedHat|Scientific)/ => $::lsbmajdistrelease ? {
      7       => "${tomcat::params::config_file_init}-${instance_name}.service",
      default => "${tomcat::params::config_file_init}-${instance_name}",
    },
    default   => "${tomcat::params::config_file_init}-${instance_name}",
  }

  $instance_init_defaults_template = $init_defaults_template ? {
    ''      => "tomcat/instance/defaults${manage_tomcat_version}-${::osfamily}.erb",
    default => $init_defaults_template
  }

  $instance_init_defaults_template_path = $::osfamily ? {
    Debian => "/etc/default/tomcat${manage_tomcat_version}-${instance_name}",
    RedHat => "/etc/sysconfig/tomcat${manage_tomcat_version}-${instance_name}",
  }

  #manage restart of the instance automatically
  $manage_instance_autorestart = $bool_instance_autorestart ? {
    true      => "Service[tomcat-${instance_name}]",
    false     => undef,
  }

  # Create instance
  $instance_create_instance_cmd_template = $create_instance_cmd_template ? {
    ''      => 'tomcat/instance/tomcat-instance-create.erb',
    default => $create_instance_cmd_template
  }

  $real_ajp_port = $ajp_port ? {
    ''      => '',
    default => "-a ${ajp_port}",
  }

  $real_runtime_dir = $runtime_dir ? {
    ''      => '',
    default => "-r ${runtime_dir}/${instance_name}",
  }

  $instance_create_instance_cmd_exec = $create_instance_cmd_exec ? {
    ''      => "/usr/bin/tomcat-instance-create -p ${http_port} -c ${control_port} ${real_ajp_port} -w ${magicword} -o ${instance_owner} -g ${instance_group} ${real_runtime_dir} ${instance_path}",
    default => $create_instance_cmd_exec,
  }

  if (!defined(File['/usr/bin/tomcat-instance-create'])) {
    file { '/usr/bin/tomcat-instance-create':
      ensure  => present,
      mode    => '0775',
      owner   => 'root',
      group   => 'root',
      content => template($instance_create_instance_cmd_template),
      before  => Exec["instance_tomcat_${instance_name}"]
    }
  }

  exec { "instance_tomcat_${instance_name}":
    command => $instance_create_instance_cmd_exec,
    creates => "${instance_path}/webapps",
    require => [ Package['tomcat'] ],
  }

  # Install Manager if $manager == true
  if $bool_manager == true {
    if (!defined(Class['tomcat::manager'])) {
      class { 'tomcat::manager':
        before => Exec["instance_tomcat_${instance_name}"],
      }
    }

    file { "instance_manager_xml_${instance_name}":
      ensure  => present,
      path    => "/etc/tomcat${manage_tomcat_version}-${instance_name}/Catalina/localhost/manager.xml",
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => Exec["instance_tomcat_${instance_name}"],
      notify  => $manage_instance_autorestart,
      content => template($manager_xml_template),
    }

  }

  # Running service
  service { "tomcat-${instance_name}":
      ensure     => $ensure_real,
      name       => "tomcat${manage_tomcat_version}-${instance_name}",
      enable     => $service_enable,
      pattern    => $instance_name,
      hasrestart => $service_hasrestart,
      hasstatus  => $tomcat::params::service_status,
      require    => Exec["instance_tomcat_${instance_name}"],
  }

  # Create service initd file
  file { "instance_tomcat_init_${instance_name}":
    ensure  => present,
    path    => $instance_tomcat_init_path,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Exec["instance_tomcat_${instance_name}"],
    notify  => $manage_instance_autorestart,
    content => template($instance_init_template),
  }

  if $tomcat::params::systemd_file_exist == 'file' {

    $instance_systemd_template = $systemd_template ? {
      ''      => "tomcat/instance/systemd${manage_instance_autorestart}-${::osfamily}.erb",
      default => $systemd_template
    }

    file { "systemd_init_${instance_name}":
      ensure  => $tomcat::params::systemd_file_exist,
      path    => "${tomcat::params::systemd_file_init}-${instance_name}",
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      require => Exec["instance_tomcat_${instance_name}"],
      notify  => $manage_instance_autorestart,
      content => template($instance_systemd_template),
    }
  }

  file { "instance_tomcat_defaults_${instance_name}":
    ensure  => present,
    path    => $instance_init_defaults_template_path,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => Exec["instance_tomcat_${instance_name}"],
    notify  => $manage_instance_autorestart,
    content => template($instance_init_defaults_template),
  }

  # catalina.properties is defined only if $catalina_properties_template is set
  if $catalina_properties_template != '' {
    file { "instance_tomcat_catalina.properties_${instance_name}":
      ensure  => present,
      path    => "${instance_path}/conf/catalina.properties",
      mode    => $filemode,
      owner   => $instance_owner,
      group   => $instance_group,
      require => Exec["instance_tomcat_${instance_name}"],
      notify  => $manage_instance_autorestart,
      content => template($catalina_properties_template),
    }
  }

  # Ensure logging.properties presence
  if $logging_properties_template != '' {
    file { "instance_tomcat_logging.properties_${instance_name}":
      ensure  => present,
      path    => "${instance_path}/conf/logging.properties",
      mode    => $filemode,
      owner   => $instance_owner,
      group   => $instance_group,
      require => Exec["instance_tomcat_${instance_name}"],
      notify  => $manage_instance_autorestart,
      content => template($logging_properties_template),
    }
  }

  # Ensure setenv.sh presence
  if $setenv_sh_template != '' {
    file { "instance_tomcat_setenv.sh_${instance_name}":
      ensure  => present,
      path    => "${instance_path}/bin/setenv.sh",
      mode    => '0755',
      owner   => $instance_owner,
      group   => $instance_group,
      require => Exec["instance_tomcat_${instance_name}"],
      notify  => $manage_instance_autorestart,
      content => template($setenv_sh_template),
    }
  }

  # Ensure params presence
  if $params_template != '' {
    file { "instance_tomcat_params_${instance_name}":
      ensure  => present,
      path    => "${instance_path}/bin/params",
      mode    => '0755',
      owner   => $instance_owner,
      group   => $instance_group,
      require => Exec["instance_tomcat_${instance_name}"],
      content => template($params_template),
    }
  }

  # Ensure startup.sh presence
  if $startup_sh_template != '' {
    file { "instance_tomcat_startup.sh_${instance_name}":
      ensure  => present,
      path    => $instance_startup,
      mode    => '0755',
      owner   => $instance_owner,
      group   => $instance_group,
      require => Exec["instance_tomcat_${instance_name}"],
      content => template($startup_sh_template),
    }
  }

  # Ensure shutdown.sh presence
  if $shutdown_sh_template != '' {
    file { "instance_tomcat_shutdown.sh_${instance_name}":
      ensure  => present,
      path    => $instance_shutdown,
      mode    => '0755',
      owner   => $instance_owner,
      group   => $instance_group,
      require => Exec["instance_tomcat_${instance_name}"],
      content => template($shutdown_sh_template),
    }
  }

  # server.xml is defined only if $server_xml_template is set
  if $server_xml_template != '' {
    file { "instance_tomcat_server.xml_${instance_name}":
      ensure  => present,
      path    => "${instance_path}/conf/server.xml",
      mode    => $filemode,
      owner   => $instance_owner,
      group   => $instance_group,
      require => Exec["instance_tomcat_${instance_name}"],
      notify  => $manage_instance_autorestart,
      content => template($server_xml_template),
    }
  }

  # context.xml is defined only if $context_xml_template is set
  if $context_xml_template != '' {
    file { "instance_tomcat_context.xml_${instance_name}":
      ensure  => present,
      path    => "${instance_path}/conf/context.xml",
      mode    => $filemode,
      owner   => $instance_owner,
      group   => $instance_group,
      require => Exec["instance_tomcat_${instance_name}"],
      notify  => $manage_instance_autorestart,
      content => template($context_xml_template),
    }
  }

  # tomcat-users.xml is defined only if $tomcat_users_xml_template is set
  if $tomcat_users_xml_template != '' {
    file { "instance_tomcat_tomcat-users.xml_${instance_name}":
      ensure  => present,
      path    => "${instance_path}/conf/tomcat-users.xml",
      mode    => $filemode,
      owner   => $instance_owner,
      group   => $instance_group,
      require => Exec["instance_tomcat_${instance_name}"],
      notify  => $manage_instance_autorestart,
      content => template($tomcat_users_xml_template),
    }
  }

  # web.xml is defined only if $web_xml_template is set
  if $web_xml_template != '' {
    file { "instance_tomcat_web.xml_${instance_name}":
      ensure  => present,
      path    => "${instance_path}/conf/web.xml",
      mode    => $filemode,
      owner   => $instance_owner,
      group   => $instance_group,
      require => Exec["instance_tomcat_${instance_name}"],
      notify  => $manage_instance_autorestart,
      content => template($web_xml_template),
    }
  }

  if ($modjk_workers_file != '') {
    tomcat::modjk::instance { $instance_name:
      workers_file   => $modjk_workers_file,
      ajp_port       => $ajp_port,
      instance_name  => $instance_name,
      host           => 'localhost',
      lbfactor       => $modjk_lbfactor,
      ping_mode      => $modjk_ping_mode,
      socket_timeout => $modjk_socket_timeout,
      domain         => $modjk_domain,
      fail_on_status => $modjk_fail_on_status,
    }
  }

  if $monitor == true {
    monitor::process { "tomcat-${instance_name}":
      process  => 'java',
      argument => $instance_name,
      service  => "tomcat-${instance_name}",
      pidfile  => "/var/run/tomcat${manage_tomcat_version}-${instance_name}.pid",
      enable   => true,
      tool     => $monitor_tool,
    }

    monitor::port { "tomcat-${instance_name}-${http_port}":
      protocol => 'tcp',
      port     => $http_port,
      target   => $::fqdn,
      enable   => true,
      tool     => $monitor_tool,
    }
  }
  if $puppi == true {
    tomcat::puppi::instance { "tomcat-${instance_name}":
      servicename => "tomcat-${instance_name}",
      processname => $instance_name,
      configdir   => "${instance_path}/conf/",
      bindir      => "${instance_path}/bin/",
      pidfile     => "/var/run/tomcat${manage_tomcat_version}-${instance_name}.pid",
      datadir     => "${instance_path}/webapps",
      logdir      => "${instance_path}/logs",
      httpport    => $http_port,
      controlport => $control_port,
      ajpport     => $ajp_port,
      description => "Info for ${instance_name} Tomcat instance" ,
    }
  }

  if $apache_vhost_create == true {
    $instance_apache_vhost_context = $apache_vhost_context ? {
      ''      => $instance_name,
      default => $apache_vhost_context,
    }

    $instance_apache_vhost_proxy_alias = $apache_vhost_proxy_alias ? {
      ''      => $ajp_port ? {
        ''      => "/${instance_apache_vhost_context} http://localhost:${http_port}/${instance_apache_vhost_context}",
        default => "/${instance_apache_vhost_context} ajp://localhost:${ajp_port}/${instance_apache_vhost_context}",
      },
      default => $apache_vhost_proxy_alias,
    }

    if ! defined(Apache::Module['proxy']) {
      apache::module { 'proxy': }
    }

    if ! defined(Apache::Module['proxy_http']) {
      apache::module { 'proxy_http': }
    }

    if ! defined(Apache::Module['proxy_ajp']) {
      if $ajp_port != '' {
        apache::module { 'proxy_ajp': }
      }
    }

    if $manager == true {
      $array_instance_apache_vhost_proxy_alias = concat( [ $instance_apache_vhost_proxy_alias ] , [ "/manager http://localhost:${http_port}/manager" ] )
    } else {
      $array_instance_apache_vhost_proxy_alias = $instance_apache_vhost_proxy_alias
    }

    if $apache_vhost_server_name == '' {
      fail('You must specify the parameter apache_vhost_server_name on your tomcat::install when apache_vhost_create == true')
    }

    $proxy_alias = $array_instance_apache_vhost_proxy_alias
    apache::vhost { $instance_name:
      server_name => $apache_vhost_server_name,
      template    => $apache_vhost_template,
      docroot     => $apache_vhost_docroot,
    }
  }

}
