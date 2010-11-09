module GitPusshuTen
  module Helpers
    module Environment
      module User

        ##
        # Removes a user from the remote server but does not remove
        # the user's home directory since it might contain applications
        def remove_user!
          response = execute_as_root("userdel -f '#{c.user}'")
          return true if response.nil? or response =~ /userdel: user .+ is currently logged in/
          false
        end

        ##
        # Adds the user to the sudoers file
        def add_user_to_sudoers!
          execute_as_root("echo '#{c.user} ALL=(ALL) ALL' >> /etc/sudoers")
        end

        ##
        # Checks the remote server to see if the provided user exists
        def user_exists?
          return false if(execute_as_root("grep '#{c.user}' /etc/passwd").nil?)
          true
        end

        ##
        # Checks to see if the user is already in the sudoers file or not
        def user_in_sudoers?
          return true if execute_as_root("cat /etc/sudoers").include?("#{c.user} ALL=(ALL) ALL")
          false
        end

        ##
        # Adds a user to the remote server and sets the home directory
        # to the path specified in the config.rb. This is the location
        # to where applications will be deployed
        #
        # If a password is not specified in the configuration, it will prompt
        # the user to fill one in here in the CLI.
        def add_user!
          if c.password.nil?
            GitPusshuTen::Log.message "What password would you like to give #{c.user.to_s.color(:yellow)}?"
            while @new_password.nil?
              new_password = ask('Fill in a password.') { |q| q.echo = false }
              new_password_verification = ask('Verify password.') { |q| q.echo = false }
              if not new_password.empty? and (new_password == new_password_verification)
                @new_password = new_password
              else
                if new_password.empty?
                  GitPusshuTen::Log.error "Please provide a password."
                else
                  GitPusshuTen::Log.error "Verification failed, please try again."
                end
              end
            end
          else
            @new_password = c.password
          end

          response = execute_as_root("useradd -m --home='#{home_dir}' -s '/bin/bash' --password='" + %x[openssl passwd #{@new_password}].chomp + "' '#{c.user}'")
          return true if response.nil? or response =~ /useradd\: warning\: the home directory already exists\./
          false
        end

      end 
    end
  end
end