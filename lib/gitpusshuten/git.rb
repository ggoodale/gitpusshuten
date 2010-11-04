module GitPusshuTen
  class Git

    ##
    # Push-To Chain
    # "type"  represents either "tag", "branch" or "ref"
    # "value" represents the value of the "type"
    attr_accessor :type, :value

    ##
    # Pushing
    # a boolean that determines whether git is currently busy pushing
    attr_accessor :pushing
    alias :pushing? :pushing

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
    # Push
    # Begin of the push(type, value).to(remote) chain
    # Pass in the type ("tag", "branch" or "ref") as the first argument
    # followed by the value of the type (e.g. "1.4.2", "develop", or "9fb5c3201186")
    def push(type, value)
      @type  = type
      @value = value
      self
    end

    ##
    # To
    # End of the push(type, value).to(remote) chain
    # Pass in the remote (e.g. "staging") as the first argument
    def to(remote)
      @pushing = true
      send("push_#{type}", value, remote)
      @pushing = false
      @type    = nil
      @value   = nil
    end

    private

    ##
    # Wrapper for the git unix utility command
    def git(command)
      %x(git #{command})
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

  end
end
