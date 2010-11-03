module GitPusshuTen
  class Initializer

    ##
    # Method to be called from CLI/Executable
    def initialize(*args)
      if not File.exist?(configuration_file)
        GitPusshuTen::Log.error "Couldn't find the GitPusshuTen configuration file in #{configuration_file}."
        exit
      end

      ##
      # Parse the CLI arguments
      cli = GitPusshuTen::CLI.new(args)

      ##
      # Load in the requested environment and it's configuration
      configuration = GitPusshuTen::Configuration.new(cli.environment).parse!(configuration_file)

      ##
      # Load in hooks
      hooks = GitPusshuTen::Hooks.new(cli.environment).parse!(hooks_file)

      ##
      # Configure the environment connection establisher
      environment = GitPusshuTen::Environment.new(configuration)

      ##
      # Bootstrap the command
      GitPusshuTen::Command.new(cli, configuration, hooks, environment)
    end

    ##
    # Path to assumed configuration file
    def configuration_file
      gitpusshuten_root + '/config.rb'
    end

    ##
    # Path to assumed hooks file
    def hooks_file
      gitpusshuten_root + '/hooks.rb'
    end

    ##
    # Path to the assumed .gitpusshuten directory
    def gitpusshuten_root
      File.expand_path(File.join(Dir.pwd, '.gitpusshuten'))
    end

  end
end