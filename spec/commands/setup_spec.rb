require 'spec_helper'

describe GitPusshuTen::Commands::Setup do

  command_setup!('Setup', %w[setup remote for staging])

  it "should extract the tag from the arguments" do
    command.object.should        == 'remote'
    command.cli.arguments.should == []
  end

  it "should not perform deploy hooks" do
    command.perform_hooks?.should be_false
  end

end