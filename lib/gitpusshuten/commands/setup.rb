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
          error "Could not find any configuration for #{y(e.name)} in your #{y(".gitpusshuten/config.rb")} file."
          error "Please add it and run #{y("gitpusshuten setup remote for #{e.name}")} to set it up with git remote."
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
          error "Unknown setup command: <#{y(object)}>"
          error "Run #{y("gitpusshuten help setup")} for a list setup commands."
        end
      end
      
      ##
      # Performs the "user" action
      def perform_user!
        if not e.installed?('git') #prompts root
          warning "It is required that you have #{y('Git')} installed at #{y(c.ip)}."
          warning "Could not find #{y('Git')}, would you like to install it?"
          
          if yes?
            Spinner.return :message => "Installing #{y('Git')}!" do
              e.install!('git-core')
            end
            if e.installed?('git')
              message "#{y('Git')} has been successfully installed!"
            else
              error "Unable to install #{y('Git')}."
              exit
            end
          else
            exit
          end
        end
        
        message "Confirming existence of user #{y(c.user)} on the #{y(e.name)} environment."
        if e.user_exists?
          message "It looks like #{y(c.user)} already exists at #{y(c.application)} (#{y(c.ip)})."
          message "Would you like to remove and re-add #{y(c.user)}?"
          if yes?
            message "Removing user #{y(c.user)} from #{y(c.application)} (#{y(c.ip)})."
            if e.remove_user!
              message "Re-adding user #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})."
              if e.add_user!
                message "Successfully re-added #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})!"
              else
                error "Failed to add user #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})."
                error "An error occurred."
                exit
              end
            else
              error "Failed to remove user #{y(c.user)} from #{y(c.application)} (#{y(c.ip)})."
              error "An error occurred."
              exit
            end
          end
        else
          message "It looks like #{y(c.user)} does not yet exist."
          message "Would you like to add #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})?"
          if yes?
            if e.add_user!
              message "Successfully added #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})!"
            else
              error "Failed to add user #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})."
              error "An error occurred."
              exit
            end
          end
        end
        
        ##
        # Install ssh key
        if e.has_ssh_key? and e.ssh_key_installed?
          message "Your ssh key is already installed for #{y(c.user)} at #{y(c.ip)}."
        else
          if e.has_ssh_key?
            message "You seem to have a ssh key in #{y(e.ssh_key_path)}"
            message "This key isn't installed for #{y(c.user)} at #{y(c.ip)}. Would you like to install it?"
            if yes?
              Spinner.return :message => "Installing your ssh key for #{y(c.user)} at #{y(c.ip)}.", :put => true do
                e.install_ssh_key!
                g("Your ssh key has been installed!")
              end
            end
          end
        end
        
        ##
        # Configure .bashrc
        if not e.execute_as_user("cat '#{File.join(c.path, '.bashrc')}'").include?('source /etc/profile')
          Spinner.return :message => "Configuring #{y('.bashrc')}.." do
            e.execute_as_user("echo -e \"export RAILS_ENV=production\nsource /etc/profile\" > '#{File.join(c.path, '.bashrc')}'")
            g('Done!')
          end
        end
        
        ##
        # Creating .gemrc
        if not e.file?(File.join(e.home_dir, '.gemrc'))
          Spinner.return :message => "Configuring #{y('.gemrc')}.." do
            e.download_packages!(e.home_dir)
            e.execute_as_user("cd #{e.home_dir}; cat gitpusshuten-packages/modules/rvm/gemrc > .gemrc")
            e.clean_up_packages!(e.home_dir)
            g('Done!')
          end
        end
        
        ##
        # Add user to sudoers file
        if not e.user_in_sudoers?
          Spinner.return :message => "Adding #{y(c.user)} to sudo-ers.." do
            e.add_user_to_sudoers!
            g('Done!')
          end
        end
        
        ##
        # Checks to see if the RVM group exists.
        # If it does exist, perform RVM specific tasks.
        if e.directory?("/usr/local/rvm")
          standard "Detected #{y('rvm')} (Ruby Version Manager), configuring #{y(c.user)} for #{y('rvm')}."
          Spinner.return :message => "Adding #{y(c.user)} to the #{y('rvm')} group.." do
            e.execute_as_root("usermod -G rvm '#{c.user}'")
            g('Done!')
          end
        end
        
        ##
        # Installs the .gitconfig and minimum configuration
        # if the configuration file does not exist.
        if not e.file?(File.join(configuration.path, '.gitconfig'))
          Spinner.return :message => "Configuring #{y('Git')} for #{y(c.user)}." do
            e.install_gitconfig!
            g('Done!')
          end
        else
          message "#{y('Git')} already configured for #{y(c.user)}."
        end
        
        ##
        # Installs PushAnd if it has not yet been installed
        if not e.directory?(File.join(configuration.path, 'pushand'))
          Spinner.return :message => "Downloading and installing #{y('Push And')} for #{y(c.user)}." do
            e.install_pushand!
            g('Done!')
          end
        else
          message "#{y('Push And')} already downloaded and installed for #{y(c.user)}."
        end
        
        ##
        # Finished adding user!
        message "Finished adding and configuring #{y(c.user)}!"
        
        ##
        # Add remote
        message "Adding #{y(e.name)} to your #{y('git remote')}."
        perform_remote!
        
        message "Finished installation!"
        message "You should now be able to push your application to #{y(c.application)} at #{y(c.ip)}."
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
        message("The #{y(e.name)} remote has been added:")
        message(configuration.user + '@' + configuration.ip + ':' + environment.app_dir + "\n")
      end

      ##
      # Performs the "sshkey"
      def perform_sshkey!
        unless e.has_ssh_key?
          error "Could not find ssh key in #{y(e.ssh_key_path)}"
          error "To create one, run: #{y('ssh-keygen -t rsa')}"
          exit
        end
        
        unless e.ssh_key_installed? # prompts root
          message "Your ssh key has not yet been installed for #{y(c.user)} at #{y(c.ip)}."
          Spinner.return :message => "Installing SSH Key.." do
            e.install_ssh_key!
            g("Your ssh key has been installed!")
          end
        else
          message "Your ssh has already been installed for #{y(c.user)} at #{y(c.ip)}."
        end
      end

    end
  end
end