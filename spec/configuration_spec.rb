require 'spec_helper'

describe GitPusshuTen::Configuration do

  let(:configuration) { GitPusshuTen::Configuration.new(:staging) }

  describe 'the environment name' do
    it "should contain the remote environment" do
      configuration.environment.should == :staging
    end
    
    it "should be a symbol object" do
      GitPusshuTen::Log.expects(:error).with('Please use symbols as environment name.') 
      configuration.expects(:exit)
      configuration.pusshuten('notasymbol', 'RSpec Production Example Application')
    end
  end
  
  describe '#parse!' do
    before do
      configuration.parse!(File.dirname(__FILE__) + '/fixtures/config.rb')
    end

    it "should extract the application and remote branch names from the staging branch" do
      configuration.application.should == 'RSpec Staging Example Application'
    end

    it "should parse the authorization details" do
      configuration.user.should       == 'git'
      configuration.password.should   == 'testtest'
      configuration.passphrase.should == 'myphrase'
      configuration.ip.should         == '123.45.678.910'
      configuration.port.should       == '20'
      configuration.use_sudo.should   == false
      configuration.path.should       == '/var/apps/'
      
      configuration.additional_modules.should == [:nginx, :passenger, :active_record]
    end
    
    it "should return self" do
      configuration.should == configuration.parse!(File.dirname(__FILE__) + '/fixtures/config.rb')
    end
  end

end 