module GitPusshuTen
  class Command
    
    ##
    # Contains an array of blacklisted commands
    # These are files that aren't actually CLI commands but just
    # classes that are used by Git プ ッ シ ュ 天
    BLACKLISTED = %w[base]
    
    ##
    # Initializes the specified command if it exists or
    # errors out when it does not exist in the commands/*.rb
    def initialize(cli, configuration)
      unless available_commands.include?(cli.command)
        GitPusshuTen::Log.error "Command <#{cli.command}> not found."
        exit
      end
      
      "GitPusshuTen::Commands::#{cli.command.classify}".constantize.new(cli, configuration)
    end
    
    ##
    # Returns an array of available commands
    def available_commands
      commands_directory.map do |command|
        unless blacklisted?(command)
          find(command)
        end
      end
    end
    
    ##
    # Returns the absolute path to each command (ruby file)
    # insidethe commands directory and returns an array of each entry
    def commands_directory
      Dir[File.expand_path(File.join(File.dirname(__FILE__), 'commands/*.rb'))]
    end
    
    ##
    # Determines whether the provided command is blacklisted or not
    def blacklisted?(command)
      BLACKLISTED.include?(find(command))
    end
    
    ##
    # Expects a (full) path to the command ruby file and returns
    # only the file name without the .rb extension
    def find(command)
      command.gsub(/\.rb/, '').split('/').last
    end
    
  end
end
