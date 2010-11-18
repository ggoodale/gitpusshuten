module GitPusshuTen
  module Commands
    class Delete < GitPusshuTen::Commands::Base
      description "Deletes the application of the specified environment."
      usage       "delete <environment> environment"
      example     "heavenly delete staging environment      # Deletes the application in the staging environment."
      example     "heavenly delete production environment   # Deletes the application in the production environment."

      def initialize(*objects)
        super
        
        help if e.name.nil?
      end

      ##
      # Deletes the application directory from the remote server
      def perform_!
        message "Are you sure you wish to delete #{y(c.application)} from the #{y(e.name)} environment (#{y(c.ip)})?"
        if yes?
          message "Deleting #{y(c.application)}."
          e.delete!
        end
      end

    end
  end
end