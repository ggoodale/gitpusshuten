require 'spec_helper'

describe GitPusshuTen::Commands::Ref do

  before do
    GitPusshuTen::Commands::Ref.any_instance.stubs(:confirm_remote!)
  end

  command_setup!('Ref', %w[ref d7ae06f6af00449fe65814b95a93083c1b6fa940 to staging])

  it "should extract the tag from the arguments" do
    command.ref.should           == 'd7ae06f6af00449fe65814b95a93083c1b6fa940'
    command.cli.arguments.should == []
  end

  it "should perform deploy hooks" do
    command.perform_hooks?.should be_true
  end

  it "should push" do
    git.expects(:git).with('push staging d7ae06f6af00449fe65814b95a93083c1b6fa940:refs/heads/master --force')
    GitPusshuTen::Log.expects(:message)
    command.perform!
  end

end