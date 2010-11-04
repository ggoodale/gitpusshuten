module GitPusshuTen
  module Commands
    class Tag < GitPusshuTen::Commands::Base

      ##
      # Tag specific attributes/arguments
      attr_accessor :tag

      ##
      # Initializes the Tag command
      def initialize(*objects)
        super
        perform_hooks!
        
        @tag = cli.arguments.shift
      end

      ##
      # Performs the Tag command
      def perform!
        git.push(:tag, tag).to(environment.name)
      end

    end
  end
end