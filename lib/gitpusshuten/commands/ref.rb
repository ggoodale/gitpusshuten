require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helpers', 'push'))

module GitPusshuTen
  module Commands
    class Ref < GitPusshuTen::Commands::Base
      include GitPusshuTen::Helpers::Push
      
      description "Pushes the specified ref to a remote environment."
      usage       "push ref <ref> to <environment>"
      example     "push ref 00cab0263ae565578f6b789c4d3bb8f1b8f8b932 to staging"
      example     "push ref d7ae06f6af00449fe65814b95a93083c1b6fa940 to production"

      ##
      # Ref specific attributes/arguments
      attr_accessor :ref

      ##
      # Initializes the Ref command
      def initialize(*objects)
        super
        perform_hooks!
        
        @ref = cli.arguments.shift
        
        help if ref.nil? or environment.name.nil?
        
        confirm_remote!
      end

      ##
      # Performs the Ref command
      def perform!
        GitPusshuTen::Log.message "Pushing ref #{ref.to_s.color(:yellow)} to the #{environment.name.to_s.color(:yellow)} environment."
        git.push(:ref, ref).to(environment.name)
      end

    end
  end
end