module GitPusshuTen
  module Commands
    class Tag < GitPusshuTen::Commands::Base

      ##
      # Tag
      attr_accessor :tag

      ##
      # Initializes the Tag command
      def initialize(cli, configuration, hooks)
        @cli           = cli
        @configuration = configuration
        @hooks         = hooks
        
        @tag           = cli.arguments.shift
      end

      ##
      # Performs the Tag command
      def perform!
        
      end

    end
  end
end