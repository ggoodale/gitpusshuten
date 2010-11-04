require 'spec_helper'

describe GitPusshuTen::Git do
  
  let(:git) { GitPusshuTen::Git.new }
  
  before do
    %x(git remote rm rspec_staging) if %x(git remote) =~ /rspec_staging/
  end
  
  describe '#has_remote?' do
    it 'should be able to see if a remote already exists' do
      git.has_remote?(:rspec_staging).should be_false
    end
    
    it 'should have a remote called staging' do
      git.expects(:git).with('remote').returns('origin production rspec_staging')
      git.has_remote?(:rspec_staging).should be_true
    end
  end
  
  describe '#add_remote' do
    it 'should add a remote with the specified url' do
      git.expects(:git).with('remote add rspec_staging someurl')
      git.add_remote(:rspec_staging, 'someurl')
    end
  end
  
  describe '#remove_remote' do
    it 'should remove a remote' do
      git.expects(:git).with('remote rm rspec_staging')
      git.remove_remote(:rspec_staging)
    end
  end
  
  describe '#pushing to a remote' do
    context 'when pushing a tag' do
      it 'should push a tag to the remote' do
        git.expects(:git).with('push rspec_staging 1.4.2~0:refs/heads/master --force')
        git.push(:tag, '1.4.2').to(:rspec_staging)
      end
    end
    
    context 'when pushing a branch' do
      it 'should push a branch to the remote' do
        git.expects(:git).with('push rspec_staging development:refs/heads/master --force')
        git.push(:branch, :development).to(:rspec_staging)
      end
    end
  
    context 'when pushing a ref' do
      it 'should push a ref to the remote' do
        git.expects(:git).with('push rspec_staging ad36b4c018f7580db48c20fa4ed7911ea50a5684:refs/heads/master --force')
        git.push(:ref, 'ad36b4c018f7580db48c20fa4ed7911ea50a5684').to(:rspec_staging)
      end
    end
  end

end