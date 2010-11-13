module GitPusshuTen
  module Commands
    class Delete < GitPusshuTen::Commands::Base
      description "Deletes the application of the specified environment."
      usage       "delete <environment> environment"
      example     "gitpusshuten delete staging environment"
      example     "gitpusshuten delete production environment"

      ##
      # Initializes the Delete command
      def initialize(*objects)
        super
        
        help if e.name.nil?
      end

      ##
      # Performs the Delete command
      def perform!
        message "Are you sure you wish to delete #{y(c.application)} from the #{y(e.name)} environment (#{y(c.ip)})?"
        if yes?
          message "Deleting #{y(c.application)}."
          e.delete!
        end
      end

    end
  end
end