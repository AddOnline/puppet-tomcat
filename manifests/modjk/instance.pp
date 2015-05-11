# Define: tomcat::modjk::instance
#
# [*workers_file*]
#  The modjk workers.properties file.
#
# [*ajp_port*]
#  The AJP port to connect.
#
# [*instance_name*]
#  The instance name.
#  Default: $name
#
# [*host*]
#  The worker member host.
#  Default: 127.0.0.1
#
# [*lbfactor*]
#  The lbfactor.
#  Default: 1
#
# [*ping_mode*]
#  The ping mode. If not set would not be printed
#  Default: ''
#
# [*domain*]
#  The domain name. If not set would not be printed
#  Default: ''
#
# [*socket_timeout*]
#  The socket timeout
#  Default: 0
#
# [*fail_on_status*]
#  The http status code to return when an error occured.
#  Default: 0
define tomcat::modjk::instance (
  $workers_file,
  $ajp_port,
  $instance_name  = $name,
  $host           = 'localhost',
  $type           = 'ajp13',
  $lbfactor       = '1',
  $ping_mode      = '',
  $socket_timeout = '0',
  $domain         = '',
  $fail_on_status = '0',
) {
    concat::fragment{"tomcat_modjk_instance_${name}":
      target  => $workers_file,
      content => template('tomcat/modjk/workers.properties-item.erb'),
    }
}
