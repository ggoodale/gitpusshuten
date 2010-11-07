module GitPusshuTen
  class Environment

    ##
    # Stores the configuration
    attr_accessor :configuration

    ##
    # Initializes the environment with the provided configuration
    def initialize(configuration)
      @configuration = configuration
    end

    ##
    # Returns the name of the environment
    def name
      configuration.environment
    end

    ##
    # Establishes a connection to the remote environment
    # to the user's home directory
    def connect(&ssh)
      @user_authenticated ||= false
      @user_password      ||= configuration.password
      @user_attempted     ||= false
      
      while not @user_authenticated
        begin
          Net::SSH.start(configuration.ip, configuration.user, {
            :password => @user_password,
            :port     => configuration.port
          }, &ssh)
          @user_authenticated = true
        rescue Net::SSH::AuthenticationFailed
          if @user_attempted
            GitPusshuTen::Log.error "Password incorrect. Please retry."
          else
            GitPusshuTen::Log.message "Please provide the password for #{configuration.user.to_s.color(:yellow)}."
            @user_attempted = true
          end
          @user_password = ask('') { |q| q.echo = false }
        end
      end
    end

    ##
    # Performs a single command on the remote environment
    # from the application root directory
    def execute(command)
      connect do |environment|
        return environment.exec!("cd '#{application_root}'; #{command}")
      end
    end

    ##
    # Returns the root of the application
    def application_root
      File.join(configuration.path, "#{sanitized_application_name}.#{configuration.environment}")
    end

    ##
    # Takes the application name from the configuration and
    # replaces spaces with underscores and downcases capitalized characters
    def sanitized_application_name
      configuration.application.gsub(' ', '_').downcase
    end

    ##
    # Checks the remote server to see if the provided user exists
    def user_exists?
      if(execute_as_root("grep '#{configuration.user}' /etc/passwd").nil?)
        return false
      else
        return true
      end
    end

    ##
    # Adds a user to the remote server and sets the home directory
    # to the path specified in the config.rb. This is the location
    # to where applications will be deployed
    #
    # If a password is not specified in the configuration, it will prompt
    # the user to fill one in here in the CLI.
    def add_user!
      if configuration.password.nil?
        GitPusshuTen::Log.message "What password would you like to give #{configuration.user.to_s.color(:yellow)}?"
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
        @new_password = configuration.password
      end
      
      response = execute_as_root("useradd -m --home='#{configuration.path}' --password='" + %x[openssl passwd #{@new_password}].chomp + "' '#{configuration.user}'")
      if response.nil? or response =~ /useradd\: warning\: the home directory already exists\./
        return true
      else
        return false
      end
    end

    ##
    # Removes a user from the remote server but does not remove
    # the user's home directory since it might contain applications
    def remove_user!
      if execute_as_root("userdel '#{configuration.user}'").nil?
        return true
      else
        return false
      end
    end

    ##
    # Determines whether the specified utility has been installed or not
    def installed?(utility)
      if execute_as_root("which #{utility}").nil?
        return false
      else
        return true
      end
    end

    ##
    # Installs Git
    def install!(utility)
      execute_as_root("apt-get install -y #{utility}")
    end

    ##
    # Installs PushAnd
    def install_pushand!
      command  = "cd '#{configuration.path}'; git clone git://github.com/meskyanichi/pushand.git;"
      command += "chown -R #{configuration.user}:#{configuration.user} pushand; '#{configuration.path}/pushand/pushand_server_uninstall'; '#{configuration.path}/pushand/pushand_server_install'"
      execute_as_root(command)
    end

    ##
    # Installs a generated .gitconfig
    def install_gitconfig!
      command  = "cd #{configuration.path}; echo -e \"[receive]\ndenyCurrentBranch = ignore\" > .gitconfig;"
      command += "chown #{configuration.user}:#{configuration.user} .gitconfig"
      execute_as_root(command)
    end

    ##
    # Tests if the specified directory exists
    def directory?(path)
      if execute_as_root("if [[ -d '#{path}' ]]; then exit; else echo 1; fi").nil?
        return true
      else
        return false
      end
    end

    ##
    # Tests if the specified file exists
    def file?(path)
      if execute_as_root("if [[ -f '#{path}' ]]; then exit; else echo 1; fi").nil?
        return true
      else
        return false
      end
    end

    ##
    # Performs a command as root
    def execute_as_root(command)
      @root_not_authenticated ||= false
      @root_password ||= nil
      while true
        begin
          Net::SSH.start(configuration.ip, 'root', {:password => @root_password, :port => configuration.port}) do |environment|
            @root_not_authenticated = true
            return environment.exec!(command)
          end
        rescue Net::SSH::AuthenticationFailed
          if @root_password.nil?
            GitPusshuTen::Log.message "Please provide your root password for #{configuration.ip.to_s.color(:yellow)}."
          else
            GitPusshuTen::Log.error "That passwords appears to be incorrect. Unable to log in. Try again!"
          end
          
          unless @root_not_authenticated
            @root_password = ask("") { |q| q.echo = false }
          end
        end
      end
    end

    ##
    # Returns the default (local) SSH key path
    def ssh_key_path
      File.join(ENV['HOME'], '.ssh', 'id_rsa.pub')
    end

    ##
    # Returns true or false, based on whether the (local) ssh key exists
    def has_ssh_key?
      File.exist?(ssh_key_path)
    end

    ##
    # Reads out the ssh key file contents
    def ssh_key
      File.read(ssh_key_path)
    end

    ##
    # Connects to the server to read out the ~/.ssh/authorized_keys
    def authorized_ssh_keys
      execute_as_root("cat '#{File.join(configuration.path, '.ssh', 'authorized_keys')}'")
    end

    ##
    # Installs the ssh key on the remote server
    def install_ssh_key!
      command  = "mkdir -p '#{File.join(configuration.path, '.ssh')}';"
      command += "echo '#{ssh_key}' >> '#{File.join(configuration.path, '.ssh', 'authorized_keys')}';"
      command += "chown -R #{configuration.user}:#{configuration.user} '#{File.join(configuration.path, '.ssh')}'"
      execute_as_root(command)
    end

    ##
    # Returns true or false, based on whether the (local) ssh
    # key has been installed on the remote server or not
    def ssh_key_installed?
      return false unless has_ssh_key?
      return true if authorized_ssh_keys.include?(ssh_key)
      false
    end

    ##
    # Deletes the current environment (application)
    def delete!
      execute("rm -rf #{application_root}")
    end

  end
end