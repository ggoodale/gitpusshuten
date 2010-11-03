require 'spec_helper'

describe GitPusshuTen::Commands::Tag do
  
  let(:configuration_file) { File.expand_path(File.dirname(__FILE__) + '/../fixtures/config.rb')         }
  let(:hooks_file)         { File.expand_path(File.dirname(__FILE__) + '/../fixtures/hooks.rb')          }
  
  let(:cli)                { GitPusshuTen::CLI.new(%w[tag 1.4.2 to staging])                             }
  let(:configuration)      { GitPusshuTen::Configuration.new(cli.environment).parse!(configuration_file) }
  let(:hooks)              { GitPusshuTen::Hooks.new(cli.environment).parse!(hooks_file)                 }
  let(:tag_command)        { GitPusshuTen::Commands::Tag.new(cli, configuration, hooks)                  }
  
  it "should extract the tag from the arguments" do
    tag_command.tag.should           == '1.4.2'
    tag_command.cli.arguments.should == []
  end
  
  
  
end