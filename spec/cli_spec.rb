require 'spec_helper'

describe GitPusshuTen::CLI do
  
  let(:cli) { GitPusshuTen::CLI.new }
  
  it "should flatten the arguments" do
    cli = GitPusshuTen::CLI.new(['tag', [['1.4.2', 'to'], 'staging']])
    cli.arguments.should == ['1.4.2']
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
      cli = GitPusshuTen::CLI.new(%w[maintenance enable for production environment])
      cli.environment.should == :production
    end
    
    it "should return the environment" do
      cli = GitPusshuTen::CLI.new(%w[maintenance enable production environment])
      cli.environment.should == :production
    end
    
    it "should return the environment" do
      cli = GitPusshuTen::CLI.new(%w[maintenance enable for production])
      cli.environment.should == :production
    end
    
    it "should return the environment" do
      cli = GitPusshuTen::CLI.new(%w[maintenance enable for pr0duct10n])
      cli.environment.should == :pr0duct10n
    end
    
    it "should return the environment" do
      cli = GitPusshuTen::CLI.new(%w[nginx upload-vhost to production])
      cli.environment.should == :production
    end
    
    it "should return the environment" do
      cli = GitPusshuTen::CLI.new(%w[nginx download-vhost from production])
      cli.environment.should == :production
    end

    it "should return the environment" do
      cli = GitPusshuTen::CLI.new(%w[user install-ssh-key on staging])
      cli.environment.should == :staging
    end
  end
  
  describe '#command' do
    it "should extract the command from the cli" do
      cli = GitPusshuTen::CLI.new(%w[maintenance on for pr0duct10n])
      cli.command.should == 'maintenance'
    end

    it "should make underscores from dashes for commands" do
      cli = GitPusshuTen::CLI.new(%w[remote command on pr0duct10n ls -la])
      cli.command.should == 'remote'
    end
  end
  
  describe '#arguments' do
    it do
      cli = GitPusshuTen::CLI.new(%w[nginx upload-vhost to production])
      cli.arguments.should == ['upload-vhost']
    end
    
    it do
      cli = GitPusshuTen::CLI.new(%w[remote command on staging ls -la])
      cli.arguments.should == ['command', 'ls', '-la']
    end
  end
  
end