require 'spec_helper'

describe GitPusshuTen::Commands::Tag do
  
  before do
    GitPusshuTen::Commands::Tag.any_instance.stubs(:confirm_remote!)
  end
  
  command_setup!('Tag', %w[tag 1.4.2 to staging])

  it "should extract the tag from the arguments" do
    command.tag.should           == '1.4.2'
    command.cli.arguments.should == []
  end

  it "should perform deploy hooks" do
    command.perform_hooks?.should be_true
  end

  it "should push" do
    git.expects(:git).with('push staging 1.4.2~0:refs/heads/master --force')
    GitPusshuTen::Log.expects(:message)
    command.perform!
  end

end