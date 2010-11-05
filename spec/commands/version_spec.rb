# encoding: utf-8
require 'spec_helper'

describe GitPusshuTen::Commands::Tag do

  command_setup!('Version', %w[version])

  it "should not perform deploy hooks" do
    command.perform_hooks?.should be_false
  end

  it "should display the version" do
    command.expects(:puts).with("Git Pusshu Ten (プッシュ点) version #{GitPusshuTen::VERSION}")
    command.perform!
  end

end