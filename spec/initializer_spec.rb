require 'spec_helper'

describe GitPusshuTen::Initializer do
  
  let(:command)       { mock('command')       }
  let(:configuration) { mock('configuration') }
  let(:hooks)         { mock('hooks')         }
  
  before do
    command.stubs(:perform!)
    GitPusshuTen::Configuration.any_instance.stubs(:parse!)
    GitPusshuTen::Hooks.any_instance.stubs(:parse!).returns(hooks)
    hooks.expects(:parse_modules!).returns(hooks)
    GitPusshuTen::Hooks.any_instance.stubs(:parse_modules!)
    GitPusshuTen::Command.stubs(:new).returns(command)
  end
  
  it "should output an error if config file could not be found" do
    configuration.expects(:strip)
    GitPusshuTen::Initializer.any_instance.expects(:exit)
    GitPusshuTen::Log.expects(:error)
    GitPusshuTen::Initializer.new(%w[tag 1.4.2 to staging], configuration)
  end
  
end