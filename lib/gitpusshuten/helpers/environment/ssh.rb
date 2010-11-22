module GitPusshuTen
  module Helpers
    module Environment
      module SSH

        ##
        # Tests if the specified directory exists
        def directory?(path)
          return true if execute_as_root("if [[ -d '#{path}' ]]; then exit; else echo 1; fi").nil?
          false
        end

        ##
        # Tests if the specified file exists
        def file?(path)
          return true if execute_as_root("if [[ -f '#{path}' ]]; then exit; else echo 1; fi").nil?
          false
        end

        ##
        # Performs a single command on the remote environment as the
        # specified user
        def execute_as(user, command)
          @passwords ||= {}
          if (c.use_sudo && user == 'root')
            true_user = c.user
            true_command = "sudo su - -c '#{command}'"
          else
            true_user = user
            true_command = command
          end

          @passwords[true_user] ||= c.password unless true_user == 'root'

          while true
            begin
              Net::SSH.start(c.ip, true_user, {
                :password   => @passwords[true_user],
                :passphrase => c.passphrase,
                :port       => c.port
              }) do |ssh|
                response = ssh.exec!(true_command)
                GitPusshuTen::Log.silent response
                return response
              end
            rescue Net::SSH::AuthenticationFailed
              if @user_attempted
                GitPusshuTen::Log.error "Password incorrect. Please retry."
              else
                GitPusshuTen::Log.message "Please provide the password for #{true_user.to_s.color(:yellow)} (#{c.ip.color(:yellow)})."
                @user_attempted = true
              end
              @passwords[user] = ask('') { |q| q.echo = false }
            end
          end
        end

        ##
        # Performs a single command on the remote environment as a user
        def execute_as_user(command)
          execute_as(c.user, command)
        end

        ##
        # Performs a command as root.
        def execute_as_root(command)
          execute_as('root', command)
        end

      end
    end
  end
end