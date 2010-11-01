require 'spec_helper'

describe GitPusshuTen::Log do
  
  it "should log a message" do
    GitPusshuTen::Log.expects(:puts).with("[message] heavenly message")
    GitPusshuTen::Log.log("heavenly message")
  end
  
  it "should log a message" do
    GitPusshuTen::Log.expects(:puts).with("[warning] heavenly message")
    GitPusshuTen::Log.warn("heavenly message")
  end
  
  it "should log a message" do
    GitPusshuTen::Log.expects(:puts).with("[error] heavenly message")
    GitPusshuTen::Log.error("heavenly message")
  end
  
end