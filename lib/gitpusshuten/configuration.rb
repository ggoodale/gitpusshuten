module GitPusshuTen
  class Configuration

    ##
    # Contains the Application's name which is extracted from
    # the selected configuration in the configuration file
    attr_accessor :application

    ##
    # Contains the environment on the remote server name which
    # is extracted from the selected configuration in the configuration file
    attr_accessor :environment

    ##
    # Returns true if the configuration has been found
    attr_accessor :found
    alias :found? :found

    ##
    # Contains the user, password, ip and port for connecting
    # and authorizing the user to the remote server
    attr_accessor :user, :password, :ip, :port

    ##
    # Contains the path to where the application should be pushed
    attr_accessor :path

    ##
    # Contains a list of modules
    attr_accessor :additional_modules

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
    # Modules
    # Helper method for adding modules
    def modules
      yield self
    end

    ##
    # Modules - Add
    # Helper method for the Modules helper to add modules to the array
    def add(module_object)
      @additional_modules << module_object
    end

    ##
    # Pusshuten
    # Helper method used to configure the configuration file
    def pusshuten(environment, application, &block)
      unless environment.is_a?(Symbol)
        GitPusshuTen::Log.error 'Please use symbols as environment name.'
        exit
      end

      if environment == @environment
        @application = application
        @found       = true
        block.call
      end
    end

    ##
    # Initializes a new configuration object
    # takes the absolute path to the configuration file
    def initialize(environment)
      @environment = environment
      @found       = false
      
      @additional_modules = []
    end

    ##
    # Parses the configuration file and loads all the
    # configuration values into the GitPusshuTen::Configuration instance
    def parse!(configuration_file)
      instance_eval(File.read(configuration_file))
      self
    end

  end
end
