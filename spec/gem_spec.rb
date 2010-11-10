require 'spec_helper'

describe GitPusshuTen::Gem do

  before do
    GitPusshuTen::Gem.any_instance.stubs(:base_url).returns(File.dirname(__FILE__) + '/fixtures')
  end

  it "should return the latest version of the Passenger gem" do
    GitPusshuTen::Gem.new(:passenger).latest_version.should match /\d+\.\d+\..+/
  end

  describe "#outdated" do
    it "should be outdated" do
      gem = GitPusshuTen::Gem.new(:passenger)
      gem.stubs(:latest_version).returns('3.0.0')
      gem.outdated?('2.9.3').should be_true
    end
    
    it "should not be outdated" do
      gem = GitPusshuTen::Gem.new(:passenger)
      gem.stubs(:latest_version).returns('3.0.0')
      gem.outdated?('3.0.0').should be_false
      gem.outdated?('3.0.1').should be_false
    end
  end

end