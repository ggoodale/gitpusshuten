require 'spec_helper'

describe GitPusshuTen::Commands::Help do

  let(:command_object) { mock('command_object') }

  describe 'running help without any arguments' do
    command_setup!('Help', %w[help])

    before do
      command.stubs(:command_object).returns(command_object)
    end

    it do
      command.command.should be_nil
    end

    it "should display a list of commands" do
      command_object.expects(:display_commands)
      command.perform!
    end

    it "should not fail" do
      command_object.stubs(:display_commands)
      command.perform!
    end
  end

  describe 'running help on a command' do
    command_setup!('Help', %w[help tag])

    before do
      command.stubs(:command_object).returns(command_object)
    end

    it do
      command.command.should == 'tag'
    end

    it "should display the usage for the tag command" do
      command_object.expects(:display_usage).with('tag')
      command.perform!
    end
  end

end
