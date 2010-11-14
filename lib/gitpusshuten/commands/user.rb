module GitPusshuTen
  module Commands
    class User < GitPusshuTen::Commands::Base
      description "Interacts with users, based on the <app_root>/.gitpusshuten/config.rb file."
      usage       "user <command> (to|for|from|on) <environment>"
      example     "gitpusshuten user add to production                # Sets up the user on the remote server for production."
      example     "gitpusshuten user reconfigure for production       # Reconfigures the user without removing applications."
      example     "gitpusshuten user remove from production           # Removes the user and all it's applications."
      example     "gitpusshuten user install-ssh-key to staging       # Installs your ssh key on the server for the user."
      example     "gitpusshuten user install-root-ssh-key to staging  # Installs your ssh key on the server for the root user."
      example     "$(gitpusshuten user login to staging)              # Logs the user in to the staging environment as user."
      example     "$(gitpusshuten user login-root to production)      # Logs the user in to the production environment as root."

      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
        
        @command = command.underscore
      end
      
      ##
      # Sets up a new UNIX user and configures it based on the .gitpusshuten/config.rb
      def perform_add!
        if not e.user_exists? # prompts root
          ensure_git_installed!           
          message "It looks like #{y(c.user)} does not yet exist."
          message "Would you like to add #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})?"
          if yes?
            message "Adding #{y(c.user)} to #{y(c.ip)}.."
            if e.add_user!
              message "Successfully added #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})!"
            else
              error "Failed to add user #{y(c.user)} to #{y(c.application)} (#{y(c.ip)})."
              error "An error occurred. Is your configuration file properly configured?"
              exit
            end
          end
        else
          error "User #{y(c.user)} already exists."
          error "If you want to remove this user, run the following command:"
          standard "\n\s\s#{y("gitpusshuten user remove from #{e.name}")}\n\n"
          error "If you just want to reconfigure the user without removing it, run the following ommand:"
          standard "\n\s\s#{(y("gitpusshuten user reconfigure for #{e.name}"))}"
          exit
        end
        
        ##
        # Configures the user
        configure_user!
        
        ##
        # Finished adding user!
        message "Finished adding and configuring #{y(c.user)}!"
        message "You should now be able to push your application to #{y(c.application)} at #{y(c.ip)}."
      end

      ##
      # Removes the user and home directory
      def perform_remove!
        if e.user_exists?
          warning "Are you #{y('SURE')} you want to remove #{y(c.user)}?"
          warning "Doing so will also remove #{y(e.home_dir)}, in which the #{y('applications')} of #{y(c.user)} are."
          if yes?
            warning "Are you #{y('REALLY')} sure?"
            if yes?
              message "Removing user #{y(c.user)} from #{y(c.ip)}."
              if e.remove_user!
                e.execute_as_root("rm -rf '#{e.home_dir}'")
                message "User #{y(c.user)} has been removed from #{y(c.ip)}."
              else
                error "Failed to remove user #{y(c.user)} from #{y(c.ip)}."
                error "An error occurred. Is your configuration file properly configured?"
                exit
              end
            end
          end
        else
          error "User #{y(c.user)} does not exist at #{y(c.ip)}."
        end
      end

      ##
      # Reconfigures the user without removing it or any applications
      def perform_reconfigure!
        if e.user_exists? # prompts root
          configure_user!
        else
          error "User #{y(c.user)} does not exist at #{y(c.ip)}."
          error "If you want to add #{y(c.user)}, run the following command:"
          standard "\n\s\s#{y("gitpusshuten user add to #{e.name}")}"
        end
      end

      ##
      # Returns a string which can be used to login the user
      def perform_login!
        if not e.user_exists?
          error "Cannot login, #{y(c.user)} does not exist."
          exit
        end
        
        puts "ssh #{c.user}@#{c.ip} -p #{c.port}"
      end

      ##
      # Returns a string which can be used to login as root
      def perform_login_root!
        puts "ssh root@#{c.ip} -p #{c.port}"
      end

      ##
      # Installs the ssh key for the application user
      def perform_install_ssh_key!
        unless e.has_ssh_key?
          error "Could not find ssh key in #{y(e.ssh_key_path)}"
          error "To create one, run: #{y('ssh-keygen -t rsa')}"
          exit
        end
        
        unless e.ssh_key_installed? # prompts root
          Spinner.return :message => "Installing SSH Key.." do
            e.install_ssh_key!
            g("Done!")
          end
        else
          message "Your ssh has already been installed for #{y(c.user)} at #{y(c.ip)}."
        end
      end

      ##
      # Installs the ssh key for the root user
      def perform_install_root_ssh_key!
        unless e.has_ssh_key?
          error "Could not find ssh key in #{y(e.ssh_key_path)}"
          error "To create one, run: #{y('ssh-keygen -t rsa')}"
          exit
        end
        
        unless e.root_ssh_key_installed? # prompts root
          Spinner.return :message => "Installing SSH Key.." do
            e.install_root_ssh_key!
            g("Done!")
          end
        else
          message "Your ssh has already been installed for #{y('root')} at #{y(c.ip)}."
        end
      end

      ##
      # Ensures that Git is installed on the remote server
      def ensure_git_installed!
        if not e.installed?('git') #prompts root
          warning "It is required that you have #{y('Git')} installed at #{y(c.ip)}."
          warning "Could not find #{y('Git')}, would you like to install it?"
          
          if yes?
            Spinner.return :message => "Installing #{y('Git')}.." do
              e.execute_as_root('apt-get update; apt-get install -y git-core')
              @git_installed = e.installed?('git')
              if @git_installed
                g("Done!")
              else
                r("Unable to install Git.")
              end
            end
            exit unless @git_installed
          else
            exit
          end
        end
      end

      ##
      # Configures the user. Overwrites all current configurations (if any exist)
      def configure_user!
        message "Configuring #{y(c.user)}."
        
        ##
        # If the user has an SSH key and it hasn't been installed
        # on the server under the current user then it'll go ahead and install it
        if e.has_ssh_key? and not e.ssh_key_installed?
          perform_install_ssh_key!
        end
        
        ##
        # Configure .bashrc
        Spinner.return :message => "Configuring #{y('.bashrc')}.." do
          e.execute_as_root("echo -e \"export RAILS_ENV=production\nsource /etc/profile\" > '#{File.join(c.path, '.bashrc')}'")
          g('Done!')
        end
        
        ##
        # Creating .gemrc
        Spinner.return :message => "Configuring #{y('.gemrc')}.." do
          e.download_packages!(e.home_dir)
          e.execute_as_root("cd #{e.home_dir}; cat gitpusshuten-packages/modules/rvm/gemrc > .gemrc")
          e.clean_up_packages!(e.home_dir)
          g('Done!')
        end
        
        ##
        # Add user to sudoers file if not already in sudo'ers
        if not e.user_in_sudoers?
          Spinner.return :message => "Adding #{y(c.user)} to sudo-ers.." do
            e.add_user_to_sudoers!
            g('Done!')
          end
        end
        
        ##
        # Checks to see if the RVM group exists.
        # If it does exist, perform RVM specific tasks.
        Spinner.return :message => "Searching for #{y('RVM')} (Ruby version Manager).." do
          @rvm_found = e.directory?("/usr/local/rvm")
          if @rvm_found
            g("Found!")
          else
            y("Not found, skipping.")
          end
        end
        if @rvm_found
          Spinner.return :message => "Adding #{y(c.user)} to the #{y('RVM')} group.." do
            e.execute_as_root("usermod -G rvm '#{c.user}'")
            g('Done!')
          end
        end
        
        ##
        # Installs the .gitconfig and minimum configuration
        # if the configuration file does not exist.
        Spinner.return :message => "Configuring #{y('Git')} for #{y(c.user)}." do
          e.install_gitconfig!
          e.install_pushand!
          g('Done!')
        end
        
        ##
        # Ensure home directory ownership is set to the user
        Spinner.return :message => "Setting permissions.." do
          e.execute_as_root("chown -R #{c.user}:#{c.user} '#{e.home_dir}'")
          g('Done!')
        end
        
        message "Finished configuring #{y(c.user)}."
      end

    end
  end
end