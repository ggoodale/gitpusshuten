module GitPusshuTen
  module Commands
    class Help < GitPusshuTen::Commands::Base
      description "Displays the command list, or the help screen for a specific command."
      usage       "help | help <command>"
      example     "gitpusshuten help"
      example     "gitpusshuten help initialize"
      example     "gitpusshuten help setup"
      example     "gitpusshuten help tag"

      ##
      # Help specific attributes/arguments
      attr_accessor :command

      ##
      # Initializes the Help command
      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
      end

      ##
      # Performs the Help command
      def perform!
        if command.nil?
          command_object.display_commands
        else
          if command_object.available_commands.include?(command)
            command_object.display_usage(command)
          else
            error "Command <#{r(command)}> not found."
          end
        end
      end
      
    end
  end
end