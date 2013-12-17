# Define: logstash-forwarder::instance
#
# This define allows you to setup an instance of logstash-forwarder
#
# === Parameters
#
# [*host*]
#   Host name or IP address of the Logstash instance to connect to
#   Value type is string
#   Default value: undef
#   This variable is optional
#
# [*port*]
#   Port number of the Logstash instance to connect to
#   Value type is number
#   Default value: undef
#   This variable is optional
#
# [*files*]
#   Array of files you wish to process
#   Value type is array
#   Default value: undef
#   This variable is optional
#
# [*ssl_ca_file*]
#   File to use for the SSL CA
#   Value type is string
#   This variable is mandatory
#
# [*fields*]
#   Extra fields to send
#   Value type is hash
#   Default value: false
#   This variable is optional
#
# [*run_as_service*]
#   Set this to true if you want to run this as a service.
#   Set to false if you only want to manage the ssl_ca_file
#   Value type is boolean
#   Default value: true
#   This variable is optional
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
define logstash-forwarder::instance(
  $ssl_ca_file,
  $host           = undef,
  $port           = undef,
  $files          = undef,
  $fields         = false,
  $run_as_service = true,
  $ensure         = $logstash::ensure
) {

  require logstash-forwarder

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644'
  }

  if ($run_as_service == true ) {

    # Input validation
    validate_string($host)

    if ! is_numeric($port) {
      fail("\"${port}\" is not a valid port parameter value")
    }

    validate_array($files)
    $logfiles = join($files,' ')

    if $fields {
      validate_hash($fields)
    }

    # Setup init file if running as a service
    $notify_logstash-forwarder = $logstash-forwarder::restart_on_change ? {
      true  => Service["logstash-forwarder-${name}"],
      false => undef,
    }

    file { "/etc/init.d/logstash-forwarder-${name}":
      ensure  => $ensure,
      mode    => '0755',
      content => template("${module_name}/etc/init.d/logstash-forwarder.erb"),
      notify  => $notify_logstash-forwarder
    }

    #### Service management

    # set params: in operation
    if $logstash-forwarder::ensure == 'present' {

      case $logstash-forwarder::status {
        # make sure service is currently running, start it on boot
        'enabled': {
          $service_ensure = 'running'
          $service_enable = true
        }
        # make sure service is currently stopped, do not start it on boot
        'disabled': {
          $service_ensure = 'stopped'
          $service_enable = false
        }
        # make sure service is currently running, do not start it on boot
        'running': {
          $service_ensure = 'running'
          $service_enable = false
        }
        # do not start service on boot, do not care whether currently running or not
        'unmanaged': {
          $service_ensure = undef
          $service_enable = false
        }
        # unknown status
        # note: don't forget to update the parameter check in init.pp if you
        #       add a new or change an existing status.
        default: {
          fail("\"${logstash-forwarder::status}\" is an unknown service status value")
        }
      }

    # set params: removal
    } else {

      # make sure the service is stopped and disabled (the removal itself will be
      # done by package.pp)
      $service_ensure = 'stopped'
      $service_enable = false
    }

    # action
    service { "logstash-forwarder-${name}":
      ensure     => $service_ensure,
      enable     => $service_enable,
      name       => $logstash-forwarder::params::service_name,
      hasstatus  => $logstash-forwarder::params::service_hasstatus,
      hasrestart => $logstash-forwarder::params::service_hasrestart,
      pattern    => $logstash-forwarder::params::service_pattern,
    }

  } else {

    $notify_logstash-forwarder = undef

  }


  file { "/etc/logstash-forwarder/${name}":
    ensure => directory,
  }

  # Setup certificate files
  file { "/etc/logstash-forwarder/${name}/ca.crt":
    ensure  => $ensure,
    source  => $ssl_ca_file,
    require => File[ "/etc/logstash-forwarder/${name}" ],
    notify  => $notify_logstash-forwarder
  }

}
