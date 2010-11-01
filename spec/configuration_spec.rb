require 'spec_helper'

describe GitPusshuTen::Configuration do

  let(:configuration) { GitPusshuTen::Configuration.new(:staging) }

  before do
  end

  it "should contain the remote branch" do
    configuration.remote_branch.should == :staging
  end

  describe '#parse!' do
    before do
      configuration.parse!(File.dirname(__FILE__) + '/fixtures/config.rb')
    end

    it "should extract the application and remote branch names from the staging branch" do
      configuration.application_name.should == 'RSpec Staging Example Application'
      configuration.remote_branch.should    == :staging
    end

    it "should parse the authorization details" do
      configuration.user.should     == 'git'
      configuration.password.should == 'testtest'
      configuration.ip.should       == '123.45.678.910'
      configuration.port.should     == '20'
      
      configuration.path.should     == '/var/apps/'

      configuration.operating_system.should == :ubuntu
      configuration.webserver.should        == :nginx
      configuration.webserver_module.should == :passenger
      configuration.framework.should        == :rails

      configuration.perform_deploy_hooks.should       == true
      configuration.perform_custom_deploy_hook.should == true
      configuration.deploy_hooks.should               == []
      configuration.custom_deploy_hooks.should        == []
    end
  end

end 