module GitPusshuTen
  module Commands
    class Help < GitPusshuTen::Commands::Base
      description "Displays the command list, or the help screen for a specific command."
      usage       "gitpusshuten help | gitpusshuten help <command>"
      example     "gitpusshuten help | gitpusshuten help tag"

      ##
      # Tag specific attributes/arguments
      attr_accessor :command

      ##
      # Initializes the Tag command
      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
      end

      ##
      # Performs the Tag command
      def perform!
        if command.nil?
          command_object.display_commands
        else
          command_object.display_usage(command)
        end
      end

      def command_object
        @command_object ||= GitPusshuTen::Command.new(cli, configuration, hooks, environment)
      end

    end
  end
end