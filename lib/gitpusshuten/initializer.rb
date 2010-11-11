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
      hooks = GitPusshuTen::Hooks.new(cli.environment, configuration).parse!(hooks_file).parse_modules!

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
      
      ##
      # Flatten Arguments to be able to test if the array is empty
      # and not an empty array in an empty array
      args.flatten!
      
      ##
      # Parses the CLI
      cli = GitPusshuTen::CLI.new(args)
      
      ##
      # Parses the Configuration
      if File.exist?(configuration_file)
        configuration = GitPusshuTen::Configuration.new(cli.environment).parse!(configuration_file)
      else
        configuration = nil
      end
      
      ##
      # Initializes the help command by default if there aren't any arguments
      if args.empty?
        GitPusshuTen::Command.new(cli, configuration, nil, nil)
        exit
      end
      
      ##
      # Append more arguments to the array below to allow more commands
      # to invoke without initializing an environment
      if %w[help version initialize].include? args.flatten.first
        "GitPusshuTen::Commands::#{args.flatten.first.classify}".constantize.new(
          cli, configuration, nil, nil
        ).perform!
        exit
      end
    end

  end
end