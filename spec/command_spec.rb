require 'spec_helper'

describe GitPusshuTen::Command do
    
  let(:cli)           { mock('cli')           }
  let(:configuration) { mock('configuration') }
  
  before do
    cli.stubs(:command).returns('non_existing_command')
  end
  
  it "should error out if the command was not found" do
    GitPusshuTen::Log.expects(:error).with('Command <non_existing_command> not found.')
    GitPusshuTen::Command.any_instance.expects(:exit)
    
    GitPusshuTen::Command.new(cli, configuration)
  end
  
  describe '#available_commands' do
    it "should display available commands without the .rb extension" do
      GitPusshuTen::Command.any_instance.stubs(:exit)
      GitPusshuTen::Log.stubs(:error)
      
      command = GitPusshuTen::Command.new(cli, configuration)
      command.expects(:commands_directory).returns([Dir.pwd + '/commands/mock_tag.rb'])
      command.available_commands.should include('mock_tag')
    end
  end
  
  it "should initialize the specified command" do
    GitPusshuTen::Command.any_instance.stubs(:exit)
    GitPusshuTen::Log.stubs(:error)
    
    GitPusshuTen::Commands::NonExistingCommand.expects(:new).with(cli, configuration)
    
    command = GitPusshuTen::Command.new(cli, configuration)
    command.stubs(:commands_directory).returns([Dir.pwd + '/commands/mock_tag.rb'])
  end
  
end