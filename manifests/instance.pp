# Define: logstashforwarder::instance
#
# This define allows you to setup an instance of logstashforwarder.
#
# NOTE: The value of $json_conf will affect certain parameters.
#
# === Parameters
#
# [*host*]
#   This value is affected by the value of $json_conf.
#   $json_conf = false
#     Host name or IP address of the Logstash instance to connect to.
#     Value type is string
#     Default value: undef
#     This variable is optional
#   $json_conf = true
#     Array of "<hostname_or_ip>:<port>" values.
#     Value type is an array of string
#     Default value: undef
#     This variable is required
#
# [*port*]
#   This value is affected by the value of $json_conf.
#   $json_conf = false
#     Port number of the Logstash instance to connect to
#     Value type is number
#     Default value: undef
#     This variable is optional
#   $json_conf = true
#     Default value: undef
#     This variable is unused
#
# [*timeout*]
#   Network timeout value when $json_conf is enabled.
#   Value type is number
#   Default value: 15
#   This value is optional
#
# [*files*]
#   This value is affected by the value of $json_conf.
#   $json_conf = false
#     Array of files you wish to process.
#     Value type is array
#     Default value: undef
#     This variable is optional
#   $json_conf = true
#     A hash of
#     Value type is hash of files configuration.
#     Default value: undef
#     This variable is optional
#
# [*json_conf*]
#   Create a JSON configuration file. This will affect how the $host, $port,
#   and $files parameters are used.
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
define logstashforwarder::instance(
  $ssl_ca_file,
  $host           = undef,
  $port           = undef,
  $timeout        = '15',
  $files          = undef,
  $json_conf      = false,
  $fields         = false,
  $run_as_service = true,
  $ensure         = $logstash::ensure
) {

  require logstashforwarder

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644'
  }

  if ($run_as_service == true ) {

    if $json_conf == false {
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
    }

    if $logstashforwarder::restart_on_change == true {
      $logstashforwarder_notify = Service["logstash-forwarder-${name}"]
      $logstashforwarder_before = undef
    } else {
      $logstashforwarder_notify = undef
      $logstashforwarder_before = Service["logstash-forwarder-${name}"]
    }

    file { "/etc/init.d/logstash-forwarder-${name}":
      ensure  => $ensure,
      mode    => '0755',
      content => template("${module_name}/etc/init.d/logstash-forwarder.erb"),
      notify  => $logstashforwarder_notify
    }

    #### Service management

    # set params: in operation
    if $logstashforwarder::ensure == 'present' {

      case $logstashforwarder::status {
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
          fail("\"${logstashforwarder::status}\" is an unknown service status value")
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
      name       => "${logstashforwarder::params::service_name}-${name}",
      hasstatus  => $logstashforwarder::params::service_hasstatus,
      hasrestart => $logstashforwarder::params::service_hasrestart,
      pattern    => $logstashforwarder::params::service_pattern,
      require    => File["/etc/init.d/logstash-forwarder-${name}"]
    }

  } else {

    $logstashforwarder_notify = undef
    $logstashforwarder_before = undef

  }

  # Configuration
  if $json_conf {
    if !is_array($host) {
      fail('When $json_conf is true $host must be an array of hostname:port values')
    }

    if ! is_numeric($timeout) {
      fail("\"${timeout}\" is not a valid timeout parameter value")
    }

    $conf_hash = {
      network => {
        'servers' => $host,
        'ssl ca'  => "/etc/logstash-forwarder/${name}/ca.crt",
        'timeout' => $timeout,
      },
      files => $files
    }


    file { "/etc/logstash-forwarder/${name}/logstash-forwarder.conf":
      mode    => '0640',
      owner   => 'root',
      group   => 'root',
      content => sorted_json($conf_hash),
      require => File["/etc/logstash-forwarder/${name}"],
      notify  => $logstashforwarder_notify,
      before  => $logstashforwarder_before
    }
  }


  file { "/etc/logstash-forwarder/${name}":
    ensure => directory,
    require => File['/etc/logstash-forwarder']
  }

  # Setup certificate files
  file { "/etc/logstash-forwarder/${name}/ca.crt":
    ensure  => $ensure,
    source  => $ssl_ca_file,
    require => File[ "/etc/logstash-forwarder/${name}" ],
    notify  => $logstashforwarder_notify,
    before  => $logstashforwarder_before
  }

}
