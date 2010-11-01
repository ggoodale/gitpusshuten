require 'spec_helper'

describe GitPusshuTen::CLI do
  
  let(:cli) { GitPusshuTen::CLI.new }
  
  it "should flatten the arguments" do
    cli = GitPusshuTen::CLI.new(['tag', [['1.4.2', 'to'], 'staging']])
    cli.arguments.should == ['tag', '1.4.2', 'to', 'staging']
  end
  
  describe "extracting the environment" do
    it "should return the environment" do
      cli = GitPusshuTen::CLI.new(%w[tag 1.4.2 to staging])
      cli.environment.should == :staging
    end
    
    it "should return the environment" do
      cli = GitPusshuTen::CLI.new(%w[delete development environment])
      cli.environment.should == :development
    end
    
    it "should return the environment" do
      cli = GitPusshuTen::CLI.new(%w[maintenance on for production environment])
      cli.environment.should == :production
    end
    
    it "should return the environment" do
      cli = GitPusshuTen::CLI.new(%w[maintenance on production environment])
      cli.environment.should == :production
    end
    
    it "should return the environment" do
      cli = GitPusshuTen::CLI.new(%w[maintenance on for production])
      cli.environment.should == :production
    end
  end
  
end