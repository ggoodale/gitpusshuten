module GitPusshuTen
  module Helpers
    module Environment
      module SCP

        ##
        # Establishes a SCP session for "root"
        def scp_as_user(direction, from, to)
          while true
            begin
              Net::SCP.start(c.ip, 'root', {
                :password   => @user_password,
                :passphrase => c.passphrase,
                :port       => c.port
              }) do |scp|
                return scp.send("#{direction}!", from, to)
              end              
            rescue Net::SCP::AuthenticationFailed
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
        # Establishes a SCP session for "root"
        def scp_as_root(direction, from, to)
          while true
            begin
              Net::SCP.start(c.ip, 'root', {
                :password   => @root_password,
                :passphrase => c.passphrase,
                :port       => c.port
              }) do |scp|
                return scp.send("#{direction}!", from, to)
              end              
            rescue Net::SSH::AuthenticationFailed
              if @root_attempted
                GitPusshuTen::Log.error "Password incorrect. Please retry."
              else
                GitPusshuTen::Log.message "Please provide the password for #{"root".color(:yellow)}."
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