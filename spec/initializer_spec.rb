require 'spec_helper'

describe GitPusshuTen::Initializer do
  
  before do
    GitPusshuTen::Configuration.any_instance.stubs(:parse!)
    GitPusshuTen::Hooks.any_instance.stubs(:parse!)
    GitPusshuTen::Command.stubs(:new)
  end
  
  it "should output an error if config file could not be found" do
    GitPusshuTen::Initializer.any_instance.expects(:exit)
    GitPusshuTen::Log.expects(:error)
    GitPusshuTen::Initializer.new(%w[tag 1.4.2 to staging])
  end
  
end