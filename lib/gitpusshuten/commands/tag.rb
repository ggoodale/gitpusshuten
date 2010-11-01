module GitPusshuTen
  module Commands
    class Tag < GitPusshuTen::Commands::Base
      
      ##
      # Tag
      attr_accessor :tag
      
      ##
      # Initializes the Tag command
      def initialize(cli, configuration)
        @cli           = cli
        @configuration = configuration
        
        @tag           = cli.arguments.shift
      end
      
      ##
      # Performs the Tag command
      def perform!
        
      end
      
    end
  end
end