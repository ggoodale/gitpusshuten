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

  describe "what happens if the object is remote" do
    let(:git) { mock('git') }
    
    before do
      command.stubs(:git).returns(git)
      GitPusshuTen::Log.stubs(:message)
    end
    
    context "when the remote does not yet exist" do
      it "should add it" do
        git.expects(:has_remote?).with(environment.name).returns(false)
        git.expects(:add_remote).with(
          environment.name,
          "git@123.45.678.910:/var/apps/rspec_staging_example_application.staging"
        )
        command.perform!
      end
    end

    context "when the remote already exists" do
      it "should remove the existing one and add the new one" do
        git.expects(:has_remote?).with(environment.name).returns(true)
        git.expects(:remove_remote).with(environment.name)
        git.expects(:add_remote).with(
          environment.name,
          "git@123.45.678.910:/var/apps/rspec_staging_example_application.staging"
        )
        command.perform!
      end
    end
    
  end
end