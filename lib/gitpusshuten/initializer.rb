module GitPusshuTen
  class Initializer

    ##
    # Method to be called from CLI/Executable
    def initialize(*args)
      invoke_independent_command!(args)
      
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
      GitPusshuTen::Command.new(cli, configuration, hooks, environment).perform!
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

    ##
    # If a command that does not rely on an initialized
    # environment, run it without attemping to parse environment
    # specific files.
    def invoke_independent_command!(args)
      if %w[help].include? args.flatten.first
        "GitPusshuTen::Commands::#{args.flatten.first.classify}".constantize.new(
          GitPusshuTen::CLI.new(args), nil, nil, nil
        ).perform!
        exit
      end
    end

  end
end