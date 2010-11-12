module GitPusshuTen
  module Commands
    class User < GitPusshuTen::Commands::Base
      description "Interacts with users, based on the <app_root>/.gitpusshuten/config.rb file."
      usage       "user <command> (to|for|from) <environment>"
      example     "gitpusshuten user add to production                # Sets up the user on the remote server for production."
      example     "gitpusshuten user reconfigure for production       # Reconfigures the user without removing applications."
      example     "gitpusshuten user remove from production           # Removes the user and all it's applications."
      example     "gitpusshuten user install ssh-key to staging       # Installs your ssh key on the server for the user."
      example     "gitpusshuten user install root-ssh-key to staging  # Installs your ssh key on the server for the root user."

      ##
      # Setup specific attributes/arguments
      attr_accessor :command

      ##
      # Initializes the Setup command
      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
        
        @command = command.underscore
      end

      ##
      # Performs the Setup command
      def perform!        
        if respond_to?("perform_#{command}!")
          send("perform_#{command}!")
        else
          error "Unknown setup command: <#{y(command)}>"
          error "Run #{y("gitpusshuten help user")} for a list user commands."
        end
      end
      
      ##
      # Sets up a new UNIX user and configures it accordingly
      def perform_add!
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
          error "User #{y(c.user)} already exists."
          error "If you want to remove this user, run the following command:"
          standard "\n\s\s#{y("gitpusshuten user remove from #{e.name}")}\n\n"
          error "If you just want to reconfigure the user without removing it, run the following ommand:"
          standard "\n\s\s#{(y("gitpusshuten user reconfigure for #{e.name}"))}"
          exit

          ##
          # REMOVE USER
          #
          # message "It looks like #{y(c.user)} already exists at #{y(c.application)} (#{y(c.ip)})."
          # message "Would you like to remove and re-add #{y(c.user)}?"
          # if yes?
          #   message "Removing user #{y(c.user)} from #{y(c.application)} (#{y(c.ip)})."
          #   if e.remove_user!
          #     message "Re-adding user #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})."
          #     if e.add_user!
          #       message "Successfully re-added #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})!"
          #     else
          #       error "Failed to add user #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})."
          #       error "An error occurred."
          #       exit
          #     end
          #   else
          #     error "Failed to remove user #{y(c.user)} from #{y(c.application)} (#{y(c.ip)})."
          #     error "An error occurred."
          #     exit
          #   end
          # end

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
        # Ask if user wants to install SSH Key already if it's locally available
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
      # Adds the git remote to the git repository
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
      # Installs the ssh key for the application user
      def perform_user_sshkey!
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

      ##
      # Installs the ssh key for the root user
      def perform_root_sshkey!
        unless e.has_ssh_key?
          error "Could not find ssh key in #{y(e.ssh_key_path)}"
          error "To create one, run: #{y('ssh-keygen -t rsa')}"
          exit
        end
        
        unless e.root_ssh_key_installed? # prompts root
          message "Your ssh key has not yet been installed for #{y('root')} at #{y(c.ip)}."
          Spinner.return :message => "Installing SSH Key.." do
            e.install_root_ssh_key!
            g("Your ssh key has been installed!")
          end
        else
          message "Your ssh has already been installed for #{y('root')} at #{y(c.ip)}."
        end
      end

    end
  end
end