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
        # Performs a single command on the remote environment as a user
        def execute_as_user(command)
          @user_password ||= c.password
          
          while true
            begin
              Net::SSH.start(c.ip, c.user, {
                :password   => @user_password,
                :passphrase => c.passphrase,
                :port       => c.port
              }) do |ssh|
                return ssh.exec!(command)
              end              
            rescue Net::SSH::AuthenticationFailed
              if @user_attempted
                GitPusshuTen::Log.error "Password incorrect. Please retry."
              else
                GitPusshuTen::Log.message "Please provide the password for #{c.user.to_s.color(:yellow)}."
                @user_attempted = true
              end
              @user_password = ask('') { |q| q.echo = false }
            end
          end
        end

        ##
        # Performs a command as root
        def execute_as_root(command)
          while true
            begin
              Net::SSH.start(c.ip, 'root', {
                :password   => @root_password,
                :passphrase => c.passphrase,
                :port       => c.port
              }) do |ssh|
                return ssh.exec!(command)
              end              
            rescue Net::SSH::AuthenticationFailed
              if @root_attempted
                GitPusshuTen::Log.error "Password incorrect. Please retry."
              else
                GitPusshuTen::Log.message "Please provide the password for #{c.user.to_s.color(:yellow)}."
                @root_attempted = true
              end
              @root_password = ask('') { |q| q.echo = false }
            end
          end
        end

      end
    end
  end
end