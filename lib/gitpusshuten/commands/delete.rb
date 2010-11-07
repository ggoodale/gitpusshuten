module GitPusshuTen
  module Commands
    class Delete < GitPusshuTen::Commands::Base
      description "Deletes the application of the specified environment."
      usage       "delete <environment> environment"
      example     "delete staging environment"
      example     "delete production environment"

      ##
      # Initializes the Delete command
      def initialize(*objects)
        super
        
        help if environment.name.nil?
      end

      ##
      # Performs the Delete command
      def perform!
        GitPusshuTen::Log.message "Are you sure you wish to delete #{app_name} from #{environment_name} environment?"
        yes = choose do |menu|
          menu.prompt = ''
          menu.choice('Yes') { true  }
          menu.choice('No')  { false }
        end

        if yes
          GitPusshuTen::Log.message "Deleting application."
          environment.delete!
          GitPusshuTen::Log.message "Application deleted."
        end
      end

    end
  end
end