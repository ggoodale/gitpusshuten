require 'spec_helper'

describe GitPusshuTen::Hooks do
  
  let(:hooks_staging)    { GitPusshuTen::Hooks.new(:staging)    }
  let(:hooks_production) { GitPusshuTen::Hooks.new(:production) }
  
  describe '#new' do
    it "should intialize a new hooks object that takes a path to the hooks file as argument" do
      hooks_staging
    end
    
    it "should set the environment" do
      hooks_staging.environment.should    == :staging
      hooks_production.environment.should == :production
    end
  end
  
  describe '#parse!' do
    it "return the object instance itself" do
      hooks_staging.should    == hooks_staging.parse!(File.expand_path(File.dirname(__FILE__) + '/fixtures/hooks.rb'))
      hooks_production.should == hooks_production.parse!(File.expand_path(File.dirname(__FILE__) + '/fixtures/hooks.rb'))
    end

    describe 'storing parsed information' do
      before do
        hooks_staging.parse!(File.expand_path(File.dirname(__FILE__) + '/fixtures/hooks.rb'))
        hooks_production.parse!(File.expand_path(File.dirname(__FILE__) + '/fixtures/hooks.rb'))
      end

      it "should load the hooks.rb file and parse it, setting values to the instance" do
        hooks_staging.to_perform.size.should    == 4
        hooks_production.to_perform.size.should == 3
      end

      it "should have 1 pre hook and 3 post hooks" do
        hooks_staging.pre_hooks.count.should  == 1
        hooks_staging.post_hooks.count.should == 3
      end

      it "should have 2 pre hook and 1 post hooks" do
        hooks_production.pre_hooks.count.should  == 2
        hooks_production.post_hooks.count.should == 1
      end

      it "should extract the commands that must be run and add them as an array to the hook" do
        hooks_staging.pre_hooks[0].commands.first.should     == 'rm -rf output'
        hooks_staging.post_hooks[1].commands.last.should     == 'touch tmp/restart.txt'
        hooks_production.post_hooks[0].commands.first.should == 'webserver update vhost'
        hooks_production.post_hooks[0].commands.last.should  == 'webserver restart'
      end
    end
  end
  
end