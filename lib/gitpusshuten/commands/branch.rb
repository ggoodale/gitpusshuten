module GitPusshuTen
  module Commands
    class Branch < GitPusshuTen::Commands::Base
      description "Pushes the specified branch to a remote environment."
      usage       "push branch <branch> to <environment>"
      example     "push branch develop to staging"
      example     "push branch master to production"

      ##
      # Branch specific attributes/arguments
      attr_accessor :branch

      ##
      # Initializes the Branch command
      def initialize(*objects)
        super
        perform_hooks!
        
        @branch = cli.arguments.shift
        
        help if branch.nil? or environment.name.nil?
      end

      ##
      # Performs the Branch command
      def perform!
        git.push(:branch, branch).to(environment.name)
      end

    end
  end
end