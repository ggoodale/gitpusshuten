module GitPusshuTen
  module Commands
    class Base

      ##
      # Command-line Interface
      attr_accessor :cli

      ##
      # Configuration (Environment)
      attr_accessor :configuration

      ##
      # This is used by the "help" command to display the
      # description of the command in the CLI
      attr_accessor :description

      ##
      # This is used by the "help" command to display the
      # usage of the command in the CLI
      attr_accessor :usage

      ##
      # The Pre-perform command
      # It should be invoked before the #perform! command
      def pre_perform!
      end

      ##
      # The Post-perform command
      # It should be invoked after the #perform! command
      def post_perform!
      end

    end
  end
end