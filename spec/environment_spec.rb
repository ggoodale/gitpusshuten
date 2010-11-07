require 'spec_helper'

describe GitPusshuTen::Environment do
  
  let(:cli)                { GitPusshuTen::CLI.new(%w[tag 1.4.2 to staging])                             }
  let(:configuration_file) { File.expand_path(File.dirname(__FILE__) + '/fixtures/config.rb')            }
  let(:configuration)      { GitPusshuTen::Configuration.new(cli.environment).parse!(configuration_file) }  
  let(:environment)        { GitPusshuTen::Environment.new(configuration)                                }
  
  it "should initialize based on the provided configuration" do
    environment.configuration.should be_an_instance_of(GitPusshuTen::Configuration)
  end
  
  describe '#application_root' do
    it "should be the <path>/<application>.<environment>" do
      environment.application_root.should == '/var/apps/rspec_staging_example_application.staging'
    end
  end
  
  describe '#name' do
    it "should return the name of the environment we're working in" do
      environment.name.should == :staging
    end
  end
  
  describe '#delete!' do
    it "should delete the application root" do
      environment.expects(:execute).with('rm -rf /var/apps/rspec_staging_example_application.staging')
      environment.delete!
    end
  end
  
  describe 'the ssh methods' do
    describe '#authorized_ssh_keys' do
      it do
        environment.expects(:execute_as_root).with("cat '/var/apps/.ssh/authorized_keys'")
        environment.authorized_ssh_keys
      end
    end
    
    describe '#install_ssh_key!' do
      it do
        environment.expects(:ssh_key).returns('mysshkey')
        environment.expects(:execute_as_root).with("mkdir -p '/var/apps/.ssh'; echo 'mysshkey' >> '/var/apps/.ssh/authorized_keys'")
        environment.install_ssh_key!
      end
    end
  end
  
end
