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
        
        GitPusshuTen::Log.message "Confirming existence of user #{user_name} on the #{environment_name} environment."
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
        # Install ssh key
        if environment.has_ssh_key? and environment.ssh_key_installed?
          GitPusshuTen::Log.message "Your ssh key is already installed for #{user_name} at #{ip_addr}."
        else
          if environment.has_ssh_key?
            GitPusshuTen::Log.message "You seem to have a ssh key in #{environment.ssh_key_path}"
            GitPusshuTen::Log.message "This key isn't installed for #{user_name} at #{ip_addr}. Would you like to install it?"
            yes = choose do |menu|
              menu.prompt = ''
              menu.choice('Yes') { true  }
              menu.choice('No')  { false }
            end
            if yes
              GitPusshuTen::Log.message "Installing your ssh key for #{user_name} at #{ip_addr}."
              environment.install_ssh_key!
              GitPusshuTen::Log.message "Your ssh key has been installed!"
            end
          end
        end
        
        ##
        # Add user to sudoers file
        if not environment.user_in_sudoers?
          environment.add_user_to_sudoers!
        end
        
        ##
        # Checks to see if the RVM group exists.
        # If it does exist, perform RVM specific tasks.
        if environment.directory?("/usr/local/rvm")          
          if not environment.execute_as_root("cat #{File.join(environment.home_dir, '.bashrc')}").
          include?("[[ -s \"/usr/local/lib/rvm\" ]] && source \"/usr/local/lib/rvm\"")
            GitPusshuTen::Log.message "Detected RVM, configuring #{user_name} for RVM."
            setup_for_rvm!
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
          configuration.user + '@' + configuration.ip + ':' + environment.app_dir
        )
        GitPusshuTen::Log.message("The " + environment.name.to_s.color(:yellow) + " remote has been added:")
        GitPusshuTen::Log.message(configuration.user + '@' + configuration.ip + ':' + environment.app_dir + "\n")
      end

      ##
      # Performs the "sshkey"
      def perform_sshkey!
        unless environment.has_ssh_key?
          GitPusshuTen::Log.error "Could not find ssh key in #{environment.ssh_key_path}"
          GitPusshuTen::Log.error "To create one, run: " + "ssh-keygen -t rsa".color(:yellow)
          exit
        end
        
        unless environment.ssh_key_installed?
          GitPusshuTen::Log.message "Your ssh key has not yet been installed for #{user_name} at #{ip_addr}."
          GitPusshuTen::Log.message "Installing now."
          environment.install_ssh_key!
          GitPusshuTen::Log.message "Your ssh key has been installed!"
        else
          GitPusshuTen::Log.message "Your ssh has already been installed for #{user_name} at #{ip_addr}."
        end
      end

      ##
      # Adds the user to the "rvm" group, downloads the .bashrc file to do the needed
      # configuration and then pushes the modified version back to the server.
      def setup_for_rvm!
        local.create_tmp_dir!
        GitPusshuTen::Log.message "Adding #{user_name} to the #{'rvm'.color(:yellow)} group."
        environment.execute_as_root("usermod -G rvm '#{configuration.user}'")
        GitPusshuTen::Log.message "Configuring #{user_name}'s " + ".bashrc".color(:yellow) + " file for " + "rvm".color(:yellow) + "."
        environment.scp_as_root(:download, File.join(environment.home_dir, '.bashrc'), File.join(local.tmp_dir, '.bashrc'))
        contents = File.read(File.join(local.tmp_dir, '.bashrc'))
        contents.sub!(/\[ \-z \"\$PS1\" \] \&\& return/, "# [ -z \"$PS1\" ] && return\n\nif [[ -n \"$PS1\" ]]; then")
        File.open(File.join(local.tmp_dir, '.bashrc'), 'w') do |file|
          file << contents
          file << "\nfi\n\n[[ -s \"/usr/local/lib/rvm\" ]] && source \"/usr/local/lib/rvm\"\n\n"
        end
        environment.scp_as_root(:upload, File.join(local.tmp_dir, '.bashrc'), File.join(environment.home_dir, '.bashrc'))
        local.remove_tmp_dir!
        GitPusshuTen::Log.message "Finished configuring #{user_name} for #{'rvm'.color(:yellow)}."
      end

    end
  end
end