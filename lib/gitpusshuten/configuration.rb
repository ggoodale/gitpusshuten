module GitPusshuTen
  class Configuration

    ##
    # Contains the Application's name which is extracted from
    # the selected configuration in the configuration file
    attr_accessor :application_name

    ##
    # Contains the remote branch name which is extracted from
    # the selected configuration in the configuration file
    attr_accessor :remote_branch

    ##
    # Contains the user, password, ip and port for connecting
    # and authorizing the user to the remote server
    attr_accessor :user, :password, :ip, :port

    ##
    # Contains the path to where the application should be pushed
    attr_accessor :path

    ##
    # Contains the operating_system, webserver, webserver_module and framework
    # that gitープッシュ天 uses to add additional pre-defined/convenient configuration
    attr_accessor :operating_system, :webserver, :webserver_module, :framework

    ##
    # Contains the perform_deploy_hooks, perform_custom_deploy_hook,
    # deploy_hooks and custom_deploy_hooks. These are used to determine
    # whether the hooks should be invoked or not, as well as push or pop
    # hooks on/off the stack
    attr_accessor :perform_deploy_hooks, :perform_custom_deploy_hook,
                  :deploy_hooks, :custom_deploy_hooks

    ##
    # Authorize
    # Helper method for the pusshuten configuration method 
    def authorize
      yield self
    end

    ##
    # Git
    # Helper method for the pusshuten configuration method
    def git
      yield self
    end

    ##
    # Environment
    # Helper method for the pusshuten configuration method
    def environment
      yield self
    end

    ##
    # Configuration
    # Helper method for the pusshuten configuration method
    def configuration
      yield self
    end

    ##
    # Pusshuten
    # Helper method used to configure the configuration file
    def pusshuten(remote_branch, application_name, &block)
      if remote_branch.to_sym == @remote_branch
        @application_name = application_name
        block.call
      end
    end

    ##
    # Initializes a new configuration object
    # takes the absolute path to the configuration file
    def initialize(remote_branch)
      @remote_branch = remote_branch
      
      @deploy_hooks        = []
      @custom_deploy_hooks = []
    end

    ##
    # Parses the configuration file and loads all the
    # configuration values into the GitPusshuTen::Configuration instance
    def parse!(configuration_file)
      instance_eval(File.read(configuration_file))
    end

  end
end