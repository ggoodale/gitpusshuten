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
          if not configuration.found?
            GitPusshuTen::Log.error "Could not find any configuration for #{environment.name.to_s.color(:yellow)} in your #{".gitpusshuten/config.rb".color(:yellow)} file."
            GitPusshuTen::Log.error "Please add it and run #{"gitpusshuten setup remote for #{environment.name}".color(:yellow)} to set it up with git remote."
            exit
          end
          
          if git.has_remote?(environment.name)
            git.remove_remote(environment.name)
          end
          git.add_remote(
            environment.name,
            configuration.user + '@' + configuration.ip + ':' + environment.application_root
          )
          GitPusshuTen::Log.message("The " + environment.name.to_s.color(:yellow) + " remote has been added:")
          GitPusshuTen::Log.message(configuration.user + '@' + configuration.ip + ':' + environment.application_root + "\n")
        end
        
        if object == 'user'
          GitPusshuTen::Log.message "Confirming existance of user #{configuration.user.to_s.color(:yellow)} on the #{configuration.environment.to_s.color(:yellow)} environment."
          if environment.user_exists?
            GitPusshuTen::Log.message "It looks like #{configuration.user.to_s.color(:yellow)} already exists at #{configuration.ip.to_s.color(:yellow)}."
            GitPusshuTen::Log.message "Would you like to remove and re-add #{configuration.user.to_s.color(:yellow)}?"
            yes = choose do |menu|
              menu.prompt = ''
              menu.choice('Yes') { true  }
              menu.choice('No')  { false }
            end
            if yes
              GitPusshuTen::Log.message "Removing user #{configuration.user.to_s.color(:yellow)} from #{configuration.ip.to_s.color(:yellow)}."
              if environment.remove_user!
                GitPusshuTen::Log.message "Re-adding user #{configuration.user.to_s.color(:yellow)} to #{configuration.ip.to_s.color(:yellow)}."
                if environment.add_user!
                  GitPusshuTen::Log.message "Successfully re-added #{configuration.user.to_s.color(:yellow)} to #{configuration.ip.to_s.color(:yellow)}!"
                else
                  GitPusshuTen::Log.error "Failed to add user #{configuration.user.to_s.color(:yellow)} to #{configuration.ip.to_s.color(:yellow)}."
                  GitPusshuTen::Log.error "An error occurred."
                end
              else
                GitPusshuTen::Log.error "Failed to remove user #{configuration.user.to_s.color(:yellow)} from #{configuration.ip.to_s.color(:yellow)}."
                GitPusshuTen::Log.error "An error occurred."
              end
            end
          else
            GitPusshuTen::Log.message "It looks like #{configuration.user.to_s.color(:yellow)} does not yet exists."
            GitPusshuTen::Log.message "Would you like to add #{configuration.user.to_s.color(:yellow)} to #{configuration.ip.to_s.color(:yellow)}?"
            yes = choose do |menu|
              menu.prompt = ''
              menu.choice('Yes') { true  }
              menu.choice('No')  { false }
            end
            if yes
              if environment.add_user!
                GitPusshuTen::Log.message "Successfully added #{configuration.user.to_s.color(:yellow)} to #{configuration.ip.to_s.color(:yellow)}!"
              else
                GitPusshuTen::Log.error "Failed to add user #{configuration.user.to_s.color(:yellow)} to #{configuration.ip.to_s.color(:yellow)}."
                GitPusshuTen::Log.error "An error occurred."
              end
            end
          end
        end
      end

    end
  end
end