Dir[File.expand_path(File.dirname(__FILE__) + '/helpers/environment/*.rb')].each do |helper|
  require helper
end

module GitPusshuTen
  class Environment

    include GitPusshuTen::Helpers::Environment::SCP
    include GitPusshuTen::Helpers::Environment::SSH
    include GitPusshuTen::Helpers::Environment::SSHKeys
    include GitPusshuTen::Helpers::Environment::Packages
    include GitPusshuTen::Helpers::Environment::User
    include GitPusshuTen::Helpers::Environment::Installers
    include GitPusshuTen::Helpers::Environment::SCP

    ##
    # Stores the configuration
    attr_accessor :configuration

    ##
    # Initializes the environment with the provided configuration
    def initialize(configuration)
      @configuration = configuration
    end

    ##
    # Shorthand for the configuration object
    def c
      configuration
    end

    ##
    # Returns the name of the environment
    def name
      c.environment
    end

    ##
    # Users home directory
    def home_dir
      c.path
    end

    ##
    # Returns the name of the application
    def app_name
      c.application
    end

    ##
    # Returns the root of the application
    def app_dir
      File.join(home_dir, "#{sanitized_app_name}.#{name}")
    end

    ##
    # Takes the application name from the configuration and
    # replaces spaces with underscores and downcases capitalized characters
    def sanitized_app_name
      app_name.gsub(' ', '_').downcase
    end

    ##
    # Deletes the current environment (application)
    def delete!
      execute_as_user("rm -rf #{app_dir}")
    end

    ##
    # Returns the .gitpusshuten local directory
    def gitpusshuten_dir
      File.join(Dir.pwd, '.gitpusshuten')
    end

    ##
    # Returns the .gitpusshuten tmp directory
    def gitpusshuten_tmp_dir
      File.join(gitpusshuten_dir, 'tmp')
    end

  end
end