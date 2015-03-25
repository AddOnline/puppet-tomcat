# Define tomcat::mod_jk
#
# Configures Apache Httpd Mod_jk
#
# For now, all it does is create a workers.properties file that can be used
# by mod_jk. Assembles based on the tomcat::instance's where the
# $tomcat::instance::modjk_workers_file equals the $tomcat::mod_jk::workers_file
#
# == Parameters
#
# Standard class parameters
# Define the general class behaviour and customizations
#
# [*workers_file*]
# The path of the workers file to generate
#
#
define tomcat::mod_jk (
  $workers_file = $name,
) {

  require tomcat

  include concat::setup

  concat { $workers_file:
    owner => $tomcat::config_file_owner,
    group => $tomcat::config_file_group,
    mode  => $tomcat::config_file_mode,
  }
  concat::fragment { "${name}-header":
    target  => $workers_file,
    content => template('tomcat/modjk/workers.properties-header.erb'),
  }

}
