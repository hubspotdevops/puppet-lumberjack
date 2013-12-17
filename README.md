# puppet-logstash-forwarder

A puppet module for managing and configuring logstash-forwarder

https://github.com/jordansissel/logstash-forwarder

This module is puppet 3 tested

## Usage

Installation, make sure service is running and will be started at boot time:

     logstash-forwarder::instance { 'foo': 
       host  => 'logstashhost',
       port  => '7200',
       files => ['/var/log/messages', '/var/log/thing/*'],
       ssl_ca_path => "puppet:///path/to/ca.crt",
     }

Removal/decommissioning:

     class { 'logstash-forwarder':
       ensure => 'absent',
     }

Install everything but disable service(s) afterwards:

     class { 'logstash-forwarder':
       status => 'disabled',
     }

