module GitPusshuTen
  class Git
    
    ##
    # Determines whether the repository has the specified remote defined
    def has_remote?(remote)
      git('remote') =~ /#{remote}/
    end
    
    ##
    # Adds the specified remote with the specified url to the git repository
    def add_remote(remote, url)
      git("remote add #{remote} #{url}")
    end
    
    ##
    # Removes the specified remote from the git repository
    def remove_remote(remote)
      git("remote rm #{remote}")
    end
    
    ##
    # Pushes the local git repository "tag" to the
    # specified remote repository's master branch (forced)
    def push_tag(tag, remote)
      git("push #{remote} #{tag}~0:refs/heads/master --force")
    end
    
    ##
    # Pushes the local git repository "branch" to the
    # specified remote repository's master branch (forced)
    def push_branch(branch, remote)
      git("push #{remote} #{branch}:refs/heads/master --force")
    end
    
    ##
    # Pushes the local git repository "ref" to the
    # specified remote repository's master branch (forced)
    def push_ref(ref, remote)
      git("push #{remote} #{ref}:refs/heads/master --force")
    end
    
    private
    
    ##
    # Wrapper for the git unix utility command
    def git(command)
      %x(git #{command})
    end
    
  end
end
