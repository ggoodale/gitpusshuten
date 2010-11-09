require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helpers', 'push'))

module GitPusshuTen
  module Commands
    class Tag < GitPusshuTen::Commands::Base
      include GitPusshuTen::Helpers::Push

      description "Pushes the specified tag to a remote environment."
      usage       "push tag <tag> to <environment>"
      example     "push tag 1.4.2 to staging"
      example     "push tag 1.4.0 to production"

      ##
      # Tag specific attributes/arguments
      attr_accessor :tag

      ##
      # Initializes the Tag command
      def initialize(*objects)
        super
        perform_hooks!
        
        @tag = cli.arguments.shift
        
        help if tag.nil? or e.name.nil?
        
        confirm_remote!
      end

      ##
      # Performs the Tag command
      def perform!
        GitPusshuTen::Log.message "Pushing tag #{y(tag)} to the #{y(e.name)} environment."
        git.push(:tag, tag).to(e.name)
      end

    end
  end
end