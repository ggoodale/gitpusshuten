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
  
end
