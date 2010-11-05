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
    
    context "when the command exists" do
      it "should display the usage for the tag command" do
        command_object.expects(:display_usage).with('tag')
        command_object.expects(:available_commands).returns(command_object)
        command_object.expects(:include?).returns(true)
        command.perform!
      end
    end

    context "when the command does not exist" do
      command_setup!('Help', %w[help idontexist])
      
      it "should display an error" do
        command_object.expects(:display_usage).never
        command_object.expects(:available_commands).returns(command_object)
        command_object.expects(:include?).returns(false)
        GitPusshuTen::Log.expects(:error).with("Command <idontexist> not found.")
        command.perform!
      end
    end
  end

end
