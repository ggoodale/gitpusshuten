# encoding: utf-8
require 'spec_helper'

describe GitPusshuTen::Commands::Initialize do

  command_setup!('Initialize', %w[initialize])
  
  before do
    command.stubs(:working_directory).returns(Dir.pwd)
    local.stubs(:execute)
  end
  
  it "should not perform deploy hooks" do
    command.perform_hooks?.should be_false
  end

  context "when allowing Git Pusshu Ten to initialize" do
    it do
      File.stubs(:directory?).returns(false)
      command.expects(:confirm_perform).returns(true)
      command.expects(:yes?).returns(true)
      GitPusshuTen::Log.expects(:message).with("Would you like to initialize Git Pusshu Ten (プッシュ点) with #{Dir.pwd}?")
      GitPusshuTen::Log.expects(:message).with("Git Pusshu Ten (プッシュ点) initialized in: #{Dir.pwd}!")
      command.perform!
    end
  end

  context "when disallowing Git Pusshu Ten to initialize" do
    it do
      command.expects(:yes?).returns(false)
      GitPusshuTen::Log.expects(:message).with("Would you like to initialize Git Pusshu Ten (プッシュ点) with #{Dir.pwd}?")
      GitPusshuTen::Log.expects(:message).with("If you wish to initialize it elsewhere, " +
      "please move into that directory and run gitpusshuten initialize again.")
      command.perform!
    end
  end
  
  context "when Git Pusshu Ten is already initialized" do
    it "should not initialize if cancelling" do
      File.stubs(:directory?).returns(true)
      GitPusshuTen::Log.expects(:warning).times(3)
      GitPusshuTen::Log.expects(:message).with("Would you like to initialize Git Pusshu Ten (プッシュ点) with #{Dir.pwd}?")
      command.expects(:yes?).returns(false)
      command.expects(:yes?).returns(true)
      local.expects(:execute).never
      command.perform!
    end
    
    it "should overwrite" do
      File.stubs(:directory?).returns(true)
      GitPusshuTen::Log.expects(:warning).times(3)
      GitPusshuTen::Log.expects(:message).with("Git Pusshu Ten (プッシュ点) initialized in: #{Dir.pwd}!")
      GitPusshuTen::Log.expects(:message).with("Would you like to initialize Git Pusshu Ten (プッシュ点) with #{Dir.pwd}?")
      command.expects(:yes?).returns(true)
      command.expects(:yes?).returns(true)
      local.expects(:execute)
      command.perform!
    end
  end
  
end