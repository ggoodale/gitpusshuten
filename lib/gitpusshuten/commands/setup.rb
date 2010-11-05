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
        if respond_to?("perform_#{object}!")
          send("perform_#{object}!")
        else
          GitPusshuTen::Log.error "Unknown setup command: <#{object}>"
          GitPusshuTen::Log.error "Run " + "gitpusshuten help setup".color(:yellow) + " for a list setup commands."
        end
      end
      
      ##
      # Performs the "user" action
      def perform_user!
        if not environment.installed?('git')
          GitPusshuTen::Log.warning "It is required that you have #{"Git".color(:yellow)} installed on your server."
          GitPusshuTen::Log.warning "Could not find #{"Git".color(:yellow)}, would you like to install it?"
          install_git = choose do |menu|
            menu.prompt = ''
            menu.choice('Yes') { true  }
            menu.choice('No')  { false }
          end
          
          if install_git
            GitPusshuTen::Log.message "Installing #{"Git".color(:yellow)}!"
            environment.install!('git-core')
            if environment.installed?('git')
              GitPusshuTen::Log.message "#{"Git".color(:yellow)} has been successfully installed!"
            else
              GitPusshuTen::Log.error "Unable to install #{"Git".color(:yellow)}."
              exit
            end
          else
            exit
          end
        end
        
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
                exit
              end
            else
              GitPusshuTen::Log.error "Failed to remove user #{configuration.user.to_s.color(:yellow)} from #{configuration.ip.to_s.color(:yellow)}."
              GitPusshuTen::Log.error "An error occurred."
              exit
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
              exit
            end
          end
        end
        
        ##
        # Installs the .gitconfig and minimum configuration
        # if the configuration file does not exist.
        if not environment.file?(File.join(configuration.path, '.gitconfig'))
          GitPusshuTen::Log.message "Creating a #{".gitconfig".color(:yellow)} for #{configuration.user.to_s.color(:yellow)}."
          environment.install_gitconfig!
        else
          GitPusshuTen::Log.message ".gitconfig ".color(:yellow) + "already installed."
        end
        
        ##
        # Installs PushAnd if it has not yet been installed
        if not environment.directory?(File.join(configuration.path, 'pushand'))
          GitPusshuTen::Log.message "Installing #{"PushAnd".color(:yellow)} for #{configuration.ip.to_s.color(:yellow)}."
          environment.install_pushand!
        else
          GitPusshuTen::Log.message "PushAnd ".color(:yellow) + "already installed."
        end
      end

      ##
      # Performs the "remote" action
      def perform_remote!
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

    end
  end
end