module GitPusshuTen
  module Commands
    class Setup < GitPusshuTen::Commands::Base
      description "Setups up various things for you, based on the .gitpusshuten/config.rb file."
      usage       "gitpusshuten setup <object> for <environment>"
      example     "gitpusshuten setup remote for staging      # Sets up the git remote for staging"
      example     "gitpusshuten setup remote for production   # Sets up the git remote for production"
      example     "gitpusshuten setup user for staging        # Sets up the user on the remote server for staging"
      example     "gitpusshuten setup user for production     # Sets up the user on the remote server for production"

      ##
      # Setup specific attributes/arguments
      attr_accessor :object

      ##
      # Initializes the Setup command
      def initialize(*objects)
        super
        
        @object = cli.arguments.shift
        
        help if object.nil? or environment.name.nil?
      end

      ##
      # Performs the Setup command
      def perform!
        if object == 'remote'
          if git.has_remote?(environment.name)
            git.remove_remote(environment.name)
          end
          git.add_remote(
            environment.name,
            configuration.user + '@' + configuration.ip + ':' + environment.application_root
          )
          GitPusshuTen::Log.message("The " + environment.name.to_s.color(:yellow) + " remote has been added:")
          GitPusshuTen::Log.message(configuration.user + '@' + configuration.ip + ':' + environment.application_root + "\n\n")
        end
      end

    end
  end
end