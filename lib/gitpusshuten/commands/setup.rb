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
        
        if not configuration.found?
          GitPusshuTen::Log.error "Could not find any configuration for #{environment_name} in your #{".gitpusshuten/config.rb".color(:yellow)} file."
          GitPusshuTen::Log.error "Please add it and run #{"gitpusshuten setup remote for #{environment.name}".color(:yellow)} to set it up with git remote."
          exit
        end
        
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
          GitPusshuTen::Log.warning "It is required that you have #{git_name} installed at #{ip_addr}."
          GitPusshuTen::Log.warning "Could not find #{git_name}, would you like to install it?"
          install_git = choose do |menu|
            menu.prompt = ''
            menu.choice('Yes') { true  }
            menu.choice('No')  { false }
          end
          
          if install_git
            GitPusshuTen::Log.message "Installing #{git_name}!"
            environment.install!('git-core')
            if environment.installed?('git')
              GitPusshuTen::Log.message "#{git_name} has been successfully installed!"
            else
              GitPusshuTen::Log.error "Unable to install #{git_name}."
              exit
            end
          else
            exit
          end
        end
        
        GitPusshuTen::Log.message "Confirming existance of user #{user_name} on the #{environment_name} environment."
        if environment.user_exists?
          GitPusshuTen::Log.message "It looks like #{user_name} already exists at #{app_name} (#{ip_addr})."
          GitPusshuTen::Log.message "Would you like to remove and re-add #{user_name}?"
          yes = choose do |menu|
            menu.prompt = ''
            menu.choice('Yes') { true  }
            menu.choice('No')  { false }
          end
          if yes
            GitPusshuTen::Log.message "Removing user #{user_name} from #{app_name} (#{ip_addr})."
            if environment.remove_user!
              GitPusshuTen::Log.message "Re-adding user #{user_name} to #{app_name} (#{ip_addr})."
              if environment.add_user!
                GitPusshuTen::Log.message "Successfully re-added #{user_name} to #{app_name} (#{ip_addr})!"
              else
                GitPusshuTen::Log.error "Failed to add user #{user_name} to #{app_name} (#{ip_addr})."
                GitPusshuTen::Log.error "An error occurred."
                exit
              end
            else
              GitPusshuTen::Log.error "Failed to remove user #{user_name} from #{app_name} (#{ip_addr})."
              GitPusshuTen::Log.error "An error occurred."
              exit
            end
          end
        else
          GitPusshuTen::Log.message "It looks like #{user_name} does not yet exist."
          GitPusshuTen::Log.message "Would you like to add #{user_name} to #{app_name} (#{ip_addr})?"
          yes = choose do |menu|
            menu.prompt = ''
            menu.choice('Yes') { true  }
            menu.choice('No')  { false }
          end
          if yes
            if environment.add_user!
              GitPusshuTen::Log.message "Successfully added #{user_name} to #{app_name} (#{ip_addr})!"
            else
              GitPusshuTen::Log.error "Failed to add user #{user_name} to #{app_name} (#{ip_addr})."
              GitPusshuTen::Log.error "An error occurred."
              exit
            end
          end
        end
        
        ##
        # Installs the .gitconfig and minimum configuration
        # if the configuration file does not exist.
        if not environment.file?(File.join(configuration.path, '.gitconfig'))
          GitPusshuTen::Log.message "Configuring #{git_name} for #{user_name}."
          environment.install_gitconfig!
        else
          GitPusshuTen::Log.message "#{git_name} already configured for #{user_name}."
        end
        
        ##
        # Installs PushAnd if it has not yet been installed
        if not environment.directory?(File.join(configuration.path, 'pushand'))
          GitPusshuTen::Log.message "Cloning and installing #{pushand_name} for #{user_name}."
          environment.install_pushand!
        else
          GitPusshuTen::Log.message "#{pushand_name} already cloned and installed for #{user_name}."
        end
        
        ##
        # Finished adding user!
        GitPusshuTen::Log.message "Finished adding and configuring #{user_name}!"
        
        ##
        # Add remote
        GitPusshuTen::Log.message "Adding #{environment_name} to your #{git_remote}."
        perform_remote!
        
        GitPusshuTen::Log.message "Finished installation!"
        GitPusshuTen::Log.message "You should now be able to push your application to #{app_name} at #{ip_addr}."
      end

      ##
      # Performs the "remote" action
      def perform_remote!
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

      private
      
      def app_name
        configuration.application.to_s.color(:yellow)
      end
      
      def ip_addr
        configuration.ip.to_s.color(:yellow)
      end
      
      def git_name
        "Git".color(:yellow)
      end
      
      def user_name
        configuration.user.to_s.color(:yellow)
      end
      
      def environment_name
        configuration.environment.to_s.color(:yellow)
      end
      
      def pushand_name
        "PushAnd".color(:yellow)
      end

      def git_remote
        "git remote".color(:yellow)
      end

    end
  end
end