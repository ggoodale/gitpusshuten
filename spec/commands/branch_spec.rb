require 'spec_helper'

describe GitPusshuTen::Commands::Branch do

  command_setup!('Branch', %w[branch develop to staging])

  it "should extract the tag from the arguments" do
    command.branch.should        == 'develop'
    command.cli.arguments.should == []
  end

  it "should perform deploy hooks" do
    command.perform_hooks?.should be_true
  end

  it "should push" do
    git.expects(:git).with('push staging develop:refs/heads/master --force')
    command.perform!
  end

end