require 'spec_helper'

describe GitPusshuTen::Hook do

  describe 'assigning a name' do
    it "should assign a name" do
      GitPusshuTen::Hook.new({
        :name => :restart_webserver
      }).name.should eql :restart_webserver
    end
  end

  describe 'assigning a type' do
    it "should set up a new pre hook" do
      GitPusshuTen::Hook.new({
        :type => :pre
      }).type.should eql :pre
    end

    it "should set up a new post hook" do
      GitPusshuTen::Hook.new({
        :type => :post
      }).type.should eql :post
    end
  end
  
  describe 'assigning commands' do
    it "should be nil if no commands are specified" do
      hook = GitPusshuTen::Hook.new({
        :commands => []
      })
      
      hook.commands.count.should == 0
    end

    it "should have an array of commands to run" do
      hook = GitPusshuTen::Hook.new({
        :commands => ['rm -rf *', 'killall', '/etc/init.d/nginx stop']
      })
      
      hook.commands.count.should == 3
      hook.commands[0].should == 'rm -rf *'
      hook.commands[1].should == 'killall'
      hook.commands[2].should == '/etc/init.d/nginx stop'
    end
  end
  
end