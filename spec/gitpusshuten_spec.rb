require 'spec_helper'

describe GitPusshuTen do
  
  it "should return the version" do
    GitPusshuTen::VERSION.should be_a(String)
  end
  
end