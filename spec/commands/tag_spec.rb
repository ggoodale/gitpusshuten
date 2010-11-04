require 'spec_helper'

describe GitPusshuTen::Commands::Tag do
  
  let(:configuration_file) { File.expand_path(File.dirname(__FILE__) + '/../fixtures/config.rb')         }
  let(:hooks_file)         { File.expand_path(File.dirname(__FILE__) + '/../fixtures/hooks.rb')          }
  
  let(:cli)                { GitPusshuTen::CLI.new(%w[tag 1.4.2 to staging])                             }
  let(:configuration)      { GitPusshuTen::Configuration.new(cli.environment).parse!(configuration_file) }
  let(:hooks)              { GitPusshuTen::Hooks.new(cli.environment).parse!(hooks_file)                 }
  let(:environment)        { GitPusshuTen::Environment.new(configuration)                                }
  let(:tag_command)        { GitPusshuTen::Commands::Tag.new(cli, configuration, hooks, environment)     }
  let(:git)                { GitPusshuTen::Git.new                                                       }
  
  before do
    tag_command.stubs(:git).returns(git)
    git.stubs(:git)
  end
  
  it "should extract the tag from the arguments" do
    tag_command.tag.should           == '1.4.2'
    tag_command.cli.arguments.should == []
  end
  
  it "should perform deploy hooks" do
    tag_command.perform_hooks?.should be_true
  end
  
  it "should push" do
    git.expects(:git).with('push staging 1.4.2~0:refs/heads/master --force')
    tag_command.perform!
  end
  
end