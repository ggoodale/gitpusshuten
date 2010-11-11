module GitPusshuTen
  module Commands
    class Setup < GitPusshuTen::Commands::Base
      description "Setups up various things for you, based on the .gitpusshuten/config.rb file."
      usage       "gitpusshuten setup <object> for <environment>"
      example     "gitpusshuten setup remote for staging      # Sets up the git remote for staging"
      example     "gitpusshuten setup user for production     # Sets up the user on the remote server for production"
      example     "gitpusshuten setup sshkey for staging      # Installs your ssh key on the remote server for staging"

      ##
      # Setup specific attributes/arguments
      attr_accessor :object

      ##
      # Initializes the Setup command
      def initialize(*objects)
        super
        
        @object = cli.arguments.shift
        
        if not c.found?
          GitPusshuTen::Log.error "Could not find any configuration for #{y(e.name)} in your #{y(".gitpusshuten/config.rb")} file."
          GitPusshuTen::Log.error "Please add it and run #{y("gitpusshuten setup remote for #{e.name}")} to set it up with git remote."
          exit
        end
        
        help if object.nil? or e.name.nil?
      end

      ##
      # Performs the Setup command
      def perform!        
        if respond_to?("perform_#{object}!")
          send("perform_#{object}!")
        else
          GitPusshuTen::Log.error "Unknown setup command: <#{y(object)}>"
          GitPusshuTen::Log.error "Run #{y("gitpusshuten help setup")} for a list setup commands."
        end
      end
      
      ##
      # Performs the "user" action
      def perform_user!
        if not e.installed?('git')
          GitPusshuTen::Log.warning "It is required that you have #{y('Git')} installed at #{y(c.ip)}."
          GitPusshuTen::Log.warning "Could not find #{y('Git')}, would you like to install it?"
          
          if yes?
            Spinner.return :message => "Installing #{y('Git')}!" do
              environment.install!('git-core')
            end
            if environment.installed?('git')
              GitPusshuTen::Log.message "#{y('Git')} has been successfully installed!"
            else
              GitPusshuTen::Log.error "Unable to install #{y('Git')}."
              exit
            end
          else
            exit
          end
        end
        
        GitPusshuTen::Log.message "Confirming existence of user #{y(c.user)} on the #{y(e.name)} environment."
        if environment.user_exists?
          GitPusshuTen::Log.message "It looks like #{y(c.user)} already exists at #{y(c.application)} (#{y(c.ip)})."
          GitPusshuTen::Log.message "Would you like to remove and re-add #{y(c.user)}?"
          if yes?
            GitPusshuTen::Log.message "Removing user #{y(c.user)} from #{y(c.application)} (#{y(c.ip)})."
            if environment.remove_user!
              GitPusshuTen::Log.message "Re-adding user #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})."
              if environment.add_user!
                GitPusshuTen::Log.message "Successfully re-added #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})!"
              else
                GitPusshuTen::Log.error "Failed to add user #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})."
                GitPusshuTen::Log.error "An error occurred."
                exit
              end
            else
              GitPusshuTen::Log.error "Failed to remove user #{y(c.user)} from #{y(c.application)} (#{y(c.ip)})."
              GitPusshuTen::Log.error "An error occurred."
              exit
            end
          end
        else
          GitPusshuTen::Log.message "It looks like #{y(c.user)} does not yet exist."
          GitPusshuTen::Log.message "Would you like to add #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})?"
          if yes?
            if environment.add_user!
              GitPusshuTen::Log.message "Successfully added #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})!"
            else
              GitPusshuTen::Log.error "Failed to add user #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})."
              GitPusshuTen::Log.error "An error occurred."
              exit
            end
          end
        end
        
        ##
        # Install ssh key
        if environment.has_ssh_key? and environment.ssh_key_installed?
          GitPusshuTen::Log.message "Your ssh key is already installed for #{y(c.user)} at #{y(c.ip)}."
        else
          if environment.has_ssh_key?
            GitPusshuTen::Log.message "You seem to have a ssh key in #{y(e.ssh_key_path)}"
            GitPusshuTen::Log.message "This key isn't installed for #{y(c.user)} at #{y(c.ip)}. Would you like to install it?"
            if yes?
              Spinner.return :message => "Installing your ssh key for #{y(c.user)} at #{y(c.ip)}.", :put => true do
                environment.install_ssh_key!
                g("Your ssh key has been installed!")
              end
            end
          end
        end
        
        ##
        # Configure .bashrc
        if not environment.execute_as_user("cat '#{File.join(c.path, '.bashrc')}'").include?('source /etc/profile')
          GitPusshuTen::Log.message "Configuring #{y('.bashrc')}."
          environment.execute_as_user("echo -e \"export RAILS_ENV=production\nsource /etc/profile\" > '#{File.join(c.path, '.bashrc')}'")
        end
        
        ##
        # Add user to sudoers file
        if not environment.user_in_sudoers?
          GitPusshuTen::Log.message "Adding #{y(c.user)} to sudo-ers."
          environment.add_user_to_sudoers!
        end
        
        ##
        # Checks to see if the RVM group exists.
        # If it does exist, perform RVM specific tasks.
        if environment.directory?("/usr/local/rvm")
          GitPusshuTen::Log.message "Detected #{y('rvm')} (Ruby Version Manager), configuring #{y(c.user)} for #{y('rvm')}."
          GitPusshuTen::Log.message "Adding #{y(c.user)} to the #{y('rvm')} group."
          e.execute_as_root("usermod -G rvm '#{c.user}'")
        end
        
        ##
        # Installs the .gitconfig and minimum configuration
        # if the configuration file does not exist.
        if not environment.file?(File.join(configuration.path, '.gitconfig'))
          GitPusshuTen::Log.message "Configuring #{y('Git')} for #{y(c.user)}."
          environment.install_gitconfig!
        else
          GitPusshuTen::Log.message "#{y('Git')} already configured for #{y(c.user)}."
        end
        
        ##
        # Installs PushAnd if it has not yet been installed
        if not environment.directory?(File.join(configuration.path, 'pushand'))
          GitPusshuTen::Log.message "Downloading and installing #{y('Push And')} for #{y(c.user)}."
          environment.install_pushand!
        else
          GitPusshuTen::Log.message "#{y('Push And')} already downloaded and installed for #{y(c.user)}."
        end
        
        ##
        # Finished adding user!
        GitPusshuTen::Log.message "Finished adding and configuring #{y(c.user)}!"
        
        ##
        # Add remote
        GitPusshuTen::Log.message "Adding #{y(e.name)} to your #{y('git remote')}."
        perform_remote!
        
        GitPusshuTen::Log.message "Finished installation!"
        GitPusshuTen::Log.message "You should now be able to push your application to #{y(c.application)} at #{y(c.ip)}."
      end

      ##
      # Performs the "remote" action
      def perform_remote!
        if git.has_remote?(environment.name)
          git.remove_remote(environment.name)
        end
        git.add_remote(
          environment.name,
          configuration.user + '@' + configuration.ip + ':' + environment.app_dir
        )
        GitPusshuTen::Log.message("The #{y(e.name)} remote has been added:")
        GitPusshuTen::Log.message(configuration.user + '@' + configuration.ip + ':' + environment.app_dir + "\n")
      end

      ##
      # Performs the "sshkey"
      def perform_sshkey!
        unless environment.has_ssh_key?
          GitPusshuTen::Log.error "Could not find ssh key in #{y(e.ssh_key_path)}"
          GitPusshuTen::Log.error "To create one, run: #{y('ssh-keygen -t rsa')}"
          exit
        end
        
        unless environment.ssh_key_installed?
          GitPusshuTen::Log.message "Your ssh key has not yet been installed for #{y(c.user)} at #{y(c.ip)}."
          GitPusshuTen::Log.message "Installing now."
          environment.install_ssh_key!
          GitPusshuTen::Log.message "Your ssh key has been installed!"
        else
          GitPusshuTen::Log.message "Your ssh has already been installed for #{y(c.user)} at #{y(c.ip)}."
        end
      end

    end
  end
end