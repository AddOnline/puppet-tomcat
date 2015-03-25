# Define: tomcat::modjk::lb
#
# [*workers_file*]
#  The modjk workers.properties file.
#
define tomcat::modjk::lb (
  $workers_file,
  $lb_name              = $name,
  $sticky_session       = true,
  $sticky_session_force = false,
  $method               = 'Request',
  $lock                 = 'Optimistic',
  $retries              = 2,
) {

    $bool_sticky_session = any2bool($sticky_session)
    $bool_sticky_session_force = any2bool($sticky_session_force)

    concat::fragment{"tomcat_modjk_lb_${name}":
      target  => $workers_file,
      content => template('tomcat/modjk/workers.properties-lb-header.erb'),
    }
}
