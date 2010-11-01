require 'spec_helper'

describe GitPusshuTen::Command do
  
  it "should error out if the command was not found" do
    GitPusshuTen::Log.expects(:error).with('Command <non_existing_command> not found.')
    GitPusshuTen::Command.any_instance.expects(:exit)
    GitPusshuTen::Command.new('non_existing_command')
  end
  
  describe '#available_commands' do
    it "should display available commands without the .rb extension" do
      GitPusshuTen::Command.any_instance.stubs(:exit)
      GitPusshuTen::Log.stubs(:error)
      
      command = GitPusshuTen::Command.new('non_existing_command')
      command.expects(:commands_directory).returns([Dir.pwd + '/commands/mock_tag.rb'])
      command.available_commands.should include('mock_tag')
    end
  end
  
end