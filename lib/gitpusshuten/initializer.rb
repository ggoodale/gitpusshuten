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
      
      
      
    end
    
    ##
    # Path to assumed configuration file
    def configuration_file
      File.expand_path(File.join(Dir.pwd, '.gitpusshuten', 'config.rb'))
    end
    
  end
end