module GitPusshuTen
  module Commands
    class Nginx < GitPusshuTen::Commands::Base
      description "[module] Enables various NGINX commands."
      usage       "nginx <command> for <environment>"
      example     "nginx setup for staging"
      example     "nginx update-vhost for staging"
      example     "nginx delete-vhost for production"
      example     "nginx start for staging"
      example     "nginx stop for production"
      example     "nginx restart for production"
      example     "nginx reload for production"

      ##
      # Passenger specific attributes/arguments
      attr_accessor :command

      ##
      # Initializes the Nginx command
      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or environment.name.nil?
        
        @command = @command.underscore
        
        ##
        # Default Configuration
        @installation_dir         = "/opt/nginx"
        @installation_dir_found   = false
        @configuration_file_found = false
      end

      ##
      # Performs the Passenger command
      def perform!
        if respond_to?("perform_#{command}!")
          send("perform_#{command}!")
        else
          GitPusshuTen::Log.error "Unknown Nginx command: <#{command}>"
          GitPusshuTen::Log.error "Run " + "gitpusshuten help nginx".color(:yellow) + " for a list setup commands."
        end
      end

      ##
      # Starts Nginx
      def perform_start!
        ensure_nginx_executable_is_installed!
        GitPusshuTen::Log.message "Starting Nginx."
        puts environment.execute_as_root("/etc/init.d/nginx start")
      end

      ##
      # Stops Nginx
      def perform_stop!
        ensure_nginx_executable_is_installed!
        GitPusshuTen::Log.message "Stopping Nginx."
        puts environment.execute_as_root("/etc/init.d/nginx stop")
      end

      ##
      # Restarts Nginx
      def perform_restart!
        ensure_nginx_executable_is_installed!
        GitPusshuTen::Log.message "Restarting Nginx."
        perform_stop!
        perform_start!
      end

      ##
      # Reload Nginx
      def perform_reload!
        ensure_nginx_executable_is_installed!
        GitPusshuTen::Log.message "Reloading Nginx."
        puts environment.execute_as_root("/etc/init.d/nginx reload")
      end

      ##
      # Sets up a vHost directory and injects a snippet into the nginx.conf
      def perform_setup!
        load_configuration!
        find_correct_paths!
        
        ##
        # Set configuration directory
        @configuration_directory = @configuration_file.split('/')
        @configuration_directory.pop
        @configuration_directory = @configuration_directory.join('/')
        
        ##
        # Creates a tmp dir
        local.create_tmp_dir!
        
        ##
        # Downloads the NGINX configuration file to tmp dir
        GitPusshuTen::Log.message "Downloading NGINX configuration file to #{local.tmp_dir}."
        environment.scp_as_root(:download, @configuration_file, local.tmp_dir)
        @configuration_file_name = @configuration_file.split('/').last
        
        ##
        # Set the path to the downloaded file
        local_file = File.join(local.tmp_dir, @configuration_file_name)
        
        if not File.read(local_file).include?('include vhosts/*;')
          GitPusshuTen::Log.message "Configuring NGINX configuration file."
          
          ##
          # Inject the 'include vhosts/*'
          contents = File.read(local_file).sub(/http(\s|\t|\n){0,}\{/, "http {\n\s\s\s\sinclude vhosts/*;\n")
          File.open(local_file, 'w') do |file|
            file << contents
          end
          
          ##
          # Make a backup of the old nginx.conf
          GitPusshuTen::Log.message "Creating a backup of old NGINX configuration file."
          environment.execute_as_root("cp '#{@configuration_file}' '#{@configuration_file}.backup'")
          
          ##
          # Upload the file back
          GitPusshuTen::Log.message "Updating NGINX configuration file."
          environment.scp_as_root(:upload, local_file, @configuration_file)
          
          ##
          # Create the vhosts dir on the server
          @vhosts_directory = File.join(@configuration_directory, 'vhosts')
          GitPusshuTen::Log.message "Creating #{@vhosts_directory} directory."
          environment.execute_as_root("mkdir #{@vhosts_directory}")
        end
        
        ##
        # Removes the tmp dir
        GitPusshuTen::Log.message "Cleaning up #{local.tmp_dir}"
        local.remove_tmp_dir!
        
        ##
        # Create NGINX directory
        # Create NGINX vhost file (if it doesn't already exist)
        # Create or Overwrite NGINX config file that stores the vhosts directory
        local.execute("mkdir -p '#{File.join(local.gitpusshuten_dir, 'nginx')}'")
        vhost_file  = File.join(local.gitpusshuten_dir, 'nginx', "#{environment.name}.vhost")
        config_file = File.join(local.gitpusshuten_dir, 'nginx', "config.yml")

        if not File.exist?(vhost_file)
          File.open(vhost_file, 'w') do |file|
            file << "server {\n"
            file << "\s\slisten 80;\n"
            file << "\s\sserver_name mydomain.com www.mydomain.com;\n"
            file << "\s\sroot #{environment.app_dir}/public;\n"
            file << "\s\s# passenger_enabled on; # for rack (rails/sinatra/merb/etc users)\n"
            file << "}\n"
          end
        end
        
        File.open(config_file, 'w') do |file|
          file << YAML::dump({
            :installation_dir         => @installation_dir,
            :configuration_directory  => @configuration_directory,
            :configuration_file       => @configuration_file
          })
        end
      end

      ##
      # Updates a local vhost
      def perform_update_vhost!
        load_configuration!
        find_correct_paths!
        
        vhost_file = File.join(local.gitpusshuten_dir, 'nginx', "#{environment.name}.vhost")
        if File.exist?(vhost_file)
          GitPusshuTen::Log.message "Uploading " + vhost_file.color(:yellow) + " to " +
          File.join(@configuration_directory, 'vhosts', "#{environment.sanitized_app_name}.#{environment.name}.vhost").color(:yellow) + "!"

          environment.scp_as_root(:upload, vhost_file, File.join(@configuration_directory, 'vhosts', "#{environment.sanitized_app_name}.#{environment.name}.vhost"))
          perform_restart!
        else
          GitPusshuTen::Log.error "Could not locate vhost file #{vhost_file.color(:yellow)}."
          GitPusshuTen::Log.error "Did you run " + "gitpusshuten nginx setup for #{environment.name}".color(:yellow) + " yet?"
          exit
        end
      end

      ##
      # Deletes a vhost
      def perform_delete_vhost!
        load_configuration!
        find_correct_paths!
        
        vhost_file = File.join(@configuration_directory, 'vhosts', "#{environment.sanitized_app_name}.#{environment.name}.vhost")
        if environment.file?(vhost_file)
          GitPusshuTen::Log.message "Deleting #{vhost_file.color(:yellow)}!"
          environment.execute_as_root("rm #{vhost_file}")
          perform_restart!
        else
          GitPusshuTen::Log.message "#{vhost_file.color(:yellow)} does not exist."
          exit
        end
      end

      ##
      # Installs the Nginx executable if it does not exist
      def ensure_nginx_executable_is_installed!
        if not environment.file?("/etc/init.d/nginx")
          GitPusshuTen::Log.message "Installing Nginx executable for starting/stopping/restarting/reloading Nginx."
          environment.download_gitpusshuten_packages!
          environment.execute_as_root("cp '#{File.join(environment.packages_dir, 'modules', 'nginx', 'nginx')}' /etc/init.d/nginx")
          environment.clean_up_gitpusshuten_packages!
        end
      end

      ##
      # Attempts to find correct paths and prompts the user for them otherwise
      def find_correct_paths!
        GitPusshuTen::Log.message "Confirming NGINX installation directory location."
        while not @installation_dir_found
          if not environment.directory?(@installation_dir)
            GitPusshuTen::Log.warning "Could not find NGINX in #{@installation_dir}."
            GitPusshuTen::Log.message "Please provide the path to the installation directory."
            @installation_dir = ask('')
          else
            GitPusshuTen::Log.message "NGINX installation directory found in #{@installation_dir}!"
            @installation_dir_found = true
          end
        end
        
        GitPusshuTen::Log.message "Confirming NGINX configuration file location."
        @configuration_file = File.join(@installation_dir, "conf", "nginx.conf") if @configuration_file.nil?
        while not @configuration_file_found
          if not environment.file?(@configuration_file)
            GitPusshuTen::Log.warning "Could not find the NGINX configuration file in #{@configuration_file}."
            GitPusshuTen::Log.message "Please provide the (full/absolute) path to the NGINX configuration file. (e.g. #{File.join(@installation_dir, "conf", "nginx.conf")})"
            @configuration_file = ask('')
          else
            GitPusshuTen::Log.message "NGINX configuration file found in #{@configuration_file}!"
            @configuration_file_found = true
          end
        end
      end

      ##
      # Load in configuration if present
      def load_configuration!
        config_file_path = File.join(local.gitpusshuten_dir, 'nginx', 'config.yml')
        if File.exist?(config_file_path)
          GitPusshuTen::Log.message "Loading configuration from #{File.join(local.gitpusshuten_dir, 'nginx', 'config.yml').color(:yellow)}."
          config = YAML::load(File.read(config_file_path))
          @installation_dir         = config[:installation_dir]
          @configuration_directory  = config[:configuration_directory]
          @configuration_file       = config[:configuration_file]
        end
      end

    end
  end
end