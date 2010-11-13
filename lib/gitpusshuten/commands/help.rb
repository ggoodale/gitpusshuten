module GitPusshuTen
  module Commands
    class Help < GitPusshuTen::Commands::Base
      description "Displays the command list, or the help screen for a specific command."
      usage       "help | help <command>"
      example     "gitpusshuten help                # Displays the main help screen."
      example     "gitpusshuten help initialize     # Displays the help screen for the initialize command."
      example     "gitpusshuten help setup          # Displays the help screen for the setup command."
      example     "gitpusshuten help tag            # Displays the help screen for the tag command."

      attr_accessor :command_name

      def initialize(*objects)
        super
        
        @command_name = cli.arguments.shift
      end

      ##
      # Displays the help screen if no arguments are specified
      # Displays the help screen for a particular command if an argument is specified
      def perform_!
        if command_name.nil?
          command_object.display_commands
        else
          if command_object.available_commands.include?(command_name)
            command_object.display_usage(command_name)
          else
            error "Command <#{r(command_name)}> not found."
          end
        end
      end
      
    end
  end
end