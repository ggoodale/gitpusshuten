module GitPusshuTen
  class Environment
    
    ##
    # Stores the configuration
    attr_accessor :configuration
    
    ##
    # Initializes the environment with the provided configuration
    def initialize(configuration)
      @configuration = configuration
    end
    
    ##
    # Establishes a connection to the remote environment
    # to the user's home directory
    def connect(&ssh)
      Net::SSH.start(configuration.ip, configuration.user, {
        :password => configuration.password,
        :port     => configuration.port
      }, &ssh)
    end
    
    ##
    # Performs a single command on the remote environment
    # from the application root directory
    def execute(command)
      connect do |environment|
        return environment.exec!("cd '#{application_root}'; #{command}")
      end
    end
    
    ##
    # Returns the root of the application
    def application_root
      File.join(configuration.path, "#{sanitized_application_name}.#{configuration.environment}")
    end
    
    ##
    # Takes the application name from the configuration and
    # replaces spaces with underscores and downcases capitalized characters
    def sanitized_application_name
      configuration.application.gsub(' ', '_').downcase
    end
    
  end
end