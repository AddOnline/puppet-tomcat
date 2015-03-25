# Define: tomcat::modjk::lb_member
#
# [*lb_name*]
#  The load balancer name
#
# [*workers_file*]
#  The modjk workers.properties file.
#
# [*lb_member_name*]
#  The load balancer member name.
#  Default: $name
#
define tomcat::modjk::lb_member (
  $lb_name,
  $workers_file,
  $lb_member_name = $name,
) {
    concat::fragment{"tomcat_modjk_lb_${lb_member_name}_${name}":
      target  => $workers_file,
      content => template('tomcat/modjk/workers.properties-lb-member.erb'),
    }
}
