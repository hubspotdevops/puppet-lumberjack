require 'spec_helper'

describe 'logstash-forwarder::instance', :type => 'define' do

  let(:title) { 'foo' }
  let(:facts) { { :operatingsystem => 'CentOS' } }
  let(:pre_condition) { 'class {"logstash-forwarder":; }' }

  context "Setup a instance with the service" do

    let :params do {
      :ssl_ca_file    => 'puppet:///path/to/ca.crt',
      :host           => 'localhost',
      :port           => 1234,
      :files          => [ '/var/log/file1', '/var/log/file2' ],
      :fields         => { 'field1' => 'value1', 'field2' => 'value2' },
      :run_as_service => true
    } end

    it { should contain_file('/etc/init.d/logstash-forwarder-foo') }
    it { should contain_file('/etc/logstash-forwarder/foo') }
    it { should contain_file('/etc/logstash-forwarder/foo/ca.crt') }

  end

  context "Setup a instance without a service" do

    let :params do {
      :ssl_ca_file    => 'puppet:///path/to/ca.crt',
      :run_as_service => false
    } end

    it { should_not contain_file('/etc/init.d/logstash-forwarder-foo') }
    it { should contain_file('/etc/logstash-forwarder/foo') }
    it { should contain_file('/etc/logstash-forwarder/foo/ca.crt') }

  end

end
