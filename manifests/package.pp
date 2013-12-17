# == Class: logstash-forwarder::package
#
# This class exists to coordinate all software package management related
# actions, functionality and logical units in a central place.
#
#
# === Parameters
#
# This class does not provide any parameters.
#
#
# === Examples
#
# This class may be imported by other classes to use its functionality:
#   class { 'logstash-forwarder::package': }
#
# It is not intended to be used directly by external resources like node
# definitions or other modules.
#
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
class logstash-forwarder::package {

  #### Package management

  # set params: in operation
  if $logstash-forwarder::ensure == 'present' {

    # Check if we want to install a specific version or not
    if $logstash-forwarder::version == false {

      $package_ensure = $logstash-forwarder::autoupgrade ? {
        true  => 'latest',
        false => 'present',
      }

    } else {

      # install specific version
      $package_ensure = $logstash-forwarder::version

    }

  # set params: removal
  } else {
    $package_ensure = 'purged'
  }

  # action
  package { $logstash-forwarder::params::package:
    ensure => $package_ensure,
  }

}
