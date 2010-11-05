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
    # Returns the name of the environment
    def name
      configuration.environment
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

    ##
    # Checks the remote server to see if the provided user exists
    def user_exists?
      Net::SSH.start(configuration.ip, 'root') do |environment|
        if(environment.exec!("grep '#{configuration.user}' /etc/passwd").nil?)
          return false
        else
          return true
        end
      end
    end

    ##
    # Adds a user to the remote server and sets the home directory
    # to the path specified in the config.rb. This is the location
    # to where applications will be deployed
    def add_user!
      Net::SSH.start(configuration.ip, 'root') do |environment|
        response = environment.exec!("useradd -m --home='#{configuration.path}' --password='#{configuration.password}' '#{configuration.user}'")
        if response.nil? or response =~ /useradd\: warning\: the home directory already exists\./
          return true
        else
          return false
        end
      end
    end

    ##
    # Removes a user from the remote server but does not remove
    # the user's home directory since it might contain applications
    def remove_user!
      Net::SSH.start(configuration.ip, 'root') do |environment|
        if environment.exec!("userdel '#{configuration.user}'").nil?
          return true
        else
          return false
        end
      end
    end

  end
end