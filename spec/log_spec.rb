require 'spec_helper'

describe GitPusshuTen::Log do
  
  it "should log a message" do
    GitPusshuTen::Log.expects(:puts).with("\e[32m[message] \e[0mheavenly message")
    GitPusshuTen::Log.message("heavenly message")
  end
  
  it "should log a message" do
    GitPusshuTen::Log.expects(:puts).with("\e[33m[warning] \e[0mheavenly message")
    GitPusshuTen::Log.warning("heavenly message")
  end
  
  it "should log a message" do
    GitPusshuTen::Log.expects(:puts).with("\e[31m[error] \e[0mheavenly message")
    GitPusshuTen::Log.error("heavenly message")
  end
  
end