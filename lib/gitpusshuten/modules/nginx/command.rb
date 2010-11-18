module GitPusshuTen
  module Commands
    class Nginx < GitPusshuTen::Commands::Base
      description "[Module] NginX commands."
      usage       "nginx <command> <for|from|to> <environment> (environment)"
      example     "heavenly nginx install to staging                   # Installs the Nginx web server"
      example     "heavenly nginx setup staging environment            # Sets up a managable vhost environment."
      example     "heavenly nginx update-configuration for staging     # Only for Passenger users, when updating Ruby/Passenger versions."
      example     "heavenly nginx download-configuration from staging  # Downloads the Nginx configuration file from the specified environment."
      example     "heavenly nginx upload-configuration to staging      # Uploads the NginX configuration file to the specified environment."
      example     "heavenly nginx create-vhost for production          # Creates a local vhost template for the specified environment."
      example     "heavenly nginx delete-vhost from production         # Deletes the remote vhost for the specified environment."
      example     "heavenly nginx upload-vhost to staging              # Uploads your local vhost to the server for the specified environment."
      example     "heavenly nginx download-vhost from production       # Downloads the remote vhost from the specified environment."
      example     "heavenly nginx start staging environment            # Starts the NginX webserver."
      example     "heavenly nginx stop production environment          # Stops the NginX webserver."
      example     "heavenly nginx restart production environment       # Restarts the NginX webserver."
      example     "heavenly nginx reload production environment        # Reloads the NginX webserver."

      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
        
        @command = @command.underscore
      end

      ##
      # Installs the NginX web server
      def perform_install!
        warning "If you are planning to use #{y('Ruby')} and #{y('Passenger')} then #{r("DON'T")} use this NginX installer."
        warning "Instead, use the Passenger module to install it."
        standard "\n\s\s#{y("heavenly passenger install to #{y(e.name)}")}\n\n"
        
        message "If you do not plan on using #{y('Ruby')} on this server, then this stand-alone installation should be fine."
        message "Do you want to continue?"
        exit unless yes?
        
        prompt_for_root_password!
        
        Spinner.return :message => "Installing NginX web server.." do
          e.install!('nginx')
          g('Done!')
        end
        message "NginX has been installed in #{y('/etc/nginx')}."
        GitPusshuTen::Initializer.new('nginx', 'setup', 'for', "#{e.name}")
      end

      ##
      # Starts Nginx
      def perform_start!
        ensure_nginx_executable_is_installed!
        message "Starting Nginx."
        puts e.execute_as_root("/etc/init.d/nginx start")
      end

      ##
      # Stops Nginx
      def perform_stop!
        ensure_nginx_executable_is_installed!
        message "Stopping Nginx."
        puts e.execute_as_root("/etc/init.d/nginx stop")
      end

      ##
      # Restarts Nginx
      def perform_restart!
        ensure_nginx_executable_is_installed!
        message "Restarting Nginx."
        perform_stop!
        perform_start!
      end

      ##
      # Reload Nginx
      def perform_reload!
        ensure_nginx_executable_is_installed!
        message "Reloading Nginx Configuration."
        puts e.execute_as_root("/etc/init.d/nginx reload")
      end

      ##
      # Sets up a vHost directory and injects a snippet into the nginx.conf
      def perform_setup!
        find_nginx!
        
        ##
        # Creates a tmp dir
        local.create_tmp_dir!
        
        ##
        # Downloads the NginX configuration file to tmp dir
        e.scp_as_root(:download, @nginx_conf, local.tmp_dir)
        
        ##
        # Set the path to the downloaded file
        local_file = File.join(local.tmp_dir, @nginx_conf_name)
        
        if not File.read(local_file).include?('include sites-enabled/*;')
          message "Configuring NginX configuration file."
          
          ##
          # Inject the 'include sites-enabled/*'
          contents = File.read(local_file).sub(/http(\s|\t|\n){0,}\{/, "http {\n\s\s\s\sinclude sites-enabled/*;\n")
          File.open(local_file, 'w') do |file|
            file << contents
          end
          
          ##
          # Make a backup of the old nginx.conf
          message "Creating a backup of old NginX configuration file."
          e.execute_as_root("cp '#{@nginx_conf}' '#{@nginx_conf}.backup.#{Time.now.to_i}'")
          
          ##
          # Upload the file back
          message "Updating NginX configuration file."
          e.scp_as_root(:upload, local_file, @nginx_conf)
          
          ##
          # Create the vhosts dir on the server
          message "Creating #{@nginx_vhosts_dir} directory."
          e.execute_as_root("mkdir -p #{@nginx_vhosts_dir}")
        end
        
        ##
        # Removes the tmp dir
        message "Cleaning up #{local.tmp_dir}"
        local.remove_tmp_dir!
        
        ##
        # Create NginX directory
        # Create NginX vhost file (if it doesn't already exist)
        create_vhost_template_file!
      end

      ##
      # Downloads the NginX configuration file
      def perform_download_config!
        find_nginx!
        if not @nginx_conf
          error "Could not find the NginX configuration file in #{y(@nginx_conf)}"
          exit
        end
        
        local_nginx_dir = File.join(local.gitpusshuten_dir, 'nginx')
        local.execute("mkdir -p '#{local_nginx_dir}'")
        Spinner.return :message => "Downloading NginX configuration file to #{y(local_nginx_dir)}.." do
          e.scp_as_root(:download, @nginx_conf, local_nginx_dir)
          g('Done!')
        end
      end

      ##
      # Uploads the NginX configuration file
      def perform_upload_config!
        find_nginx!
        if not e.directory?('/etc/nginx')
          error "Could not find the NginX installation directory in #{y('/etc/nginx')}"
          exit
        end

        local_configuration_file = File.join(local.gitpusshuten_dir, 'nginx', 'nginx.conf')        
        if not File.exist?(local_configuration_file)
          error "Could not find the local NginX configuration file in #{y(local_configuration_file)}"
          exit
        end
        
        Spinner.return :message => "Uploading NginX configuration file #{y(local_configuration_file)}.." do
          e.scp_as_root(:upload, local_configuration_file, @nginx_conf)
          g('Done!')
        end
      end

      ##
      # Updates a local vhost
      def perform_upload_vhost!
        find_nginx!
                
        if not e.directory?(@nginx_vhosts_dir)
          error "Could not upload your vhost because the vhost directory does not exist on the server."
          error "Did you run #{y("heavenly nginx setup for #{e.name}")} yet?"
          exit
        end
        
        vhost_file = File.join(local.gitpusshuten_dir, 'nginx', "#{e.name}.vhost")
        if File.exist?(vhost_file)
          message "Uploading #{y(vhost_file)} to " + y(File.join(@nginx_vhosts_dir, "#{e.sanitized_app_name}.#{e.name}.vhost!"))
          
          prompt_for_root_password!
          
          Spinner.return :message => "Uploading vhost.." do
            e.scp_as_root(:upload, vhost_file, File.join(@nginx_vhosts_dir, "#{e.sanitized_app_name}.#{e.name}.vhost"))
            g("Finished uploading!")
          end
          
          perform_restart!
        else
          error "Could not locate vhost file #{y(vhost_file)}."
          error "Did you run #{y("heavenly nginx setup for #{e.name}")} yet?"
          exit
        end
      end

      ##
      # Deletes a vhost
      def perform_delete_vhost!
        find_nginx!
        
        vhost_file = File.join(@nginx_vhosts_dir, "#{e.sanitized_app_name}.#{e.name}.vhost")
        if e.file?(vhost_file)
          Spinner.return :message => "Deleting #{y(vhost_file)}!" do
            e.execute_as_root("rm #{vhost_file}")
            g('Done!')
          end
          perform_reload!
        else
          message "#{y(vhost_file)} does not exist."
          exit
        end
      end

      ##
      # Creates a vhost
      def perform_create_vhost!
        create_vhost_template_file!
      end

      ##
      # Performs the Update Configuration command
      # This is particularly used when you change Passenger or Ruby versions
      # so these are updated in the nginx.conf file.
      def perform_update_configuration!
        find_nginx!
        
        message "Checking the #{y(@nginx_conf)} for current Passenger configuration."
        config_contents = e.execute_as_root("cat '#{@nginx_conf}'")
        if not config_contents.include? 'passenger_root' or not config_contents.include?('passenger_ruby')
          error "Could not find Passenger configuration, has it ever been set up?"
          exit
        end
        
        message "Checking if Passenger is installed under the #{y('default')} Ruby."
        if not e.installed?('passenger')
          message "Passenger isn't installed for the current Ruby"
          Spinner.return :message => "Installing latest Phusion Passenger Gem.." do
            e.execute_as_root('gem install passenger --no-ri --no-rdoc')
            g("Done!")
          end
        end
        
        Spinner.return :message => "Finding current Phusion Passenger Gem version..." do
          if e.execute_as_root('passenger-config --version') =~ /(\d+\.\d+\..+)/
            @passenger_version = $1.chomp.strip
            g('Found!')
          else
            r('Could not find the current Passenger version.')
          end
        end
        
        exit if @passenger_version.nil?
        
        Spinner.return :message => "Finding current Ruby version for the current Phusion Passenger Gem.." do
          if e.execute_as_root('passenger-config --root') =~ /\/usr\/local\/rvm\/gems\/(.+)\/gems\/passenger-.+/
            @ruby_version = $1.chomp.strip
            g('Found!')
          else
            r("Could not find the current Ruby version under which the Passenger Gem has been installed.")
          end
        end
        
        exit if @ruby_version.nil?
        
        puts <<-INFO


  [Detected Versions]

    Ruby Version:               #{@ruby_version}
    Phusion Passenger Version:  #{@passenger_version}


        INFO
        
        message "NginX will now be configured to work with the above versions. Is this correct?"
        exit unless yes?
        
        ##
        # Checks to see if Passengers WatchDog is available in the current Passenger gem
        # If it is not, then Passenger needs to run the "passenger-install-nginx-module" so it gets installed
        if not e.directory?("/usr/local/rvm/gems/#{@ruby_version}/gems/passenger-#{@passenger_version}/agents")
          message "Phusion Passenger has not yet been installed for this Ruby's Passenger Gem."
          message "You need to update #{y('NginX')} and #{y('Passenger')} to proceed with the configuration.\n\n"
          message "Would you like to update #{y('NginX')} and #{y('Phusion Passenger')} #{y(@passenger_version)} for #{y(@ruby_version)}?"
          message "NOTE: Your current #{y('NginX')} configuration will #{g('not')} be lost."
          
          if yes?
            Spinner.return :message => "Ensuring #{y('Phusion Passenger')} and #{y('NginX')} dependencies are installed.." do
              e.install!("build-essential libcurl4-openssl-dev bison openssl libreadline5 libreadline5-dev curl git-core zlib1g zlib1g-dev libssl-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev")
              g("Done!")
            end
            
            message "Installing NginX with the Phusion Passenger Module."
            Spinner.return :message => "Installing, this may take a while.." do
              e.execute_as_root("passenger-install-nginx-module --auto --auto-download --prefix='/etc/nginx'")
              g("Done!")
            end
          else
            exit
          end
        end
        
        ##
        # Creates a tmp dir
        local.create_tmp_dir!
        
        ##
        # Downloads the NGINX configuration file to tmp dir
        message "Updating Phusion Passenger paths in the NginX Configuration."
        Spinner.return :message => "Configuring NginX.." do
          e.scp_as_root(:download, @nginx_conf, local.tmp_dir)
          
          local_configuration_file = File.join(local.tmp_dir, @nginx_conf_name)
          update = File.read(local_configuration_file)
          update.sub! /passenger_root \/usr\/local\/rvm\/gems\/(.+)\/gems\/passenger\-(.+)\;/,
                      "passenger_root /usr/local/rvm/gems/#{@ruby_version}/gems/passenger-#{@passenger_version};"
          
          update.sub! /passenger_ruby \/usr\/local\/rvm\/wrappers\/(.+)\/ruby\;/,
                      "passenger_ruby /usr/local/rvm/wrappers/#{@ruby_version}/ruby;"
          
          File.open(local_configuration_file, 'w') do |file|
            file << update
          end
          
          ##
          # Create a backup of the current configuration file
          e.execute_as_root("cp '#{@nginx_conf}' '#{@nginx_conf}.backup.#{Time.now.to_i}'")
          
          ##
          # Upload the updated NginX configuration file
          e.scp_as_root(:upload, local_configuration_file, @nginx_conf)
          
          ##
          # Remove the local tmp directory
          local.remove_tmp_dir!
          
          g("Done!")
        end
        
        message "NginX configuration file has been updated!"
        message "#{y(@nginx_conf)}\n\n"
        
        warning "If you changed #{y('Ruby versions')}, be sure that all your application gems are installed."
        warning "If you only updated #{y('Phusion Passenger')} and did not change #{y('Ruby versions')}"
        warning "then you should be able to just restart #{y('NginX')} right away since all application gems should still be in tact.\n\n"
        
        message "When ready, run the following command to restart #{y('NginX')} and have the applied updates take effect:"
        standard "\n\s\s#{y("heavenly nginx restart for #{e.name}")}"
      end

      def perform_download_vhost!
        load_configuration!
        find_correct_paths!
        
        remote_vhost = File.join(@nginx_vhosts_dir, "#{e.sanitized_app_name}.#{e.name}.vhost")
        if not e.file?(remote_vhost) # prompts root
          error "There is no vhost currently present in #{y(remote_vhost)}."
          exit
        end
        
        local_vhost = File.join(local.gitpusshuten_dir, 'nginx', "#{e.name}.vhost")
        if File.exist?(local_vhost)
          warning "#{y(local_vhost)} already exists. Do you want to overwrite it?"
          exit unless yes?
        end
        
        local.execute("mkdir -p #{File.join(local.gitpusshuten_dir, 'nginx')}")
        Spinner.return :message => "Downloading vhost.." do
          e.scp_as_root(:download, remote_vhost, local_vhost)
          g("Finished downloading!")
        end
        message "You can find the vhost in: #{y(local_vhost)}."
      end

      ##
      # Installs the Nginx executable if it does not exist
      def ensure_nginx_executable_is_installed!
        if not e.file?("/etc/init.d/nginx")
          message "Installing NginX executable for starting/stopping/restarting/reloading Nginx."
          e.download_packages!('$HOME', :root)
          e.execute_as_root("cp $HOME/gitpusshuten-packages/modules/nginx/nginx /etc/init.d/nginx")
          e.clean_up_packages!('$HOME', :root)
        end
      end

      ##
      # Creates a vhost template file if it doesn't already exist.
      def create_vhost_template_file!
        local.execute("mkdir -p '#{File.join(local.gitpusshuten_dir, 'nginx')}'")
        vhost_file  = File.join(local.gitpusshuten_dir, 'nginx', "#{e.name}.vhost")
        
        create_file = true
        if File.exist?(vhost_file)
          warning "#{y(vhost_file)} already exists, do you want to overwrite it?"
          create_file = yes?
        end
        
        if create_file
          File.open(vhost_file, 'w') do |file|
            file << "server {\n"
            file << "\s\slisten 80;\n"
            file << "\s\sserver_name mydomain.com www.mydomain.com;\n"
            file << "\s\sroot #{e.app_dir}/public;\n"
            file << "\s\s# passenger_enabled on; # For Phusion Passenger users\n"
            file << "}\n"
          end
          message "The vhost has been created in #{y(vhost_file)}."
        end
      end

      ##
      # Finds and sets the NginX Conf path
      def find_nginx!
        ##
        # NginX Conf path you get from Passenger
        if e.file?('/etc/nginx/conf/nginx.conf')
          @nginx_conf     = '/etc/nginx/conf/nginx.conf'
          @nginx_conf_dir = '/etc/nginx/conf'
        end
        
        ##
        # NginX Conf path you get from Aptitude
        if e.file?('/etc/nginx/nginx.conf')
          @nginx_conf     = '/etc/nginx/nginx.conf'
          @nginx_conf_dir = '/etc/nginx'
        end
        
        ##
        # Set additional configuration
        @nginx_conf_name  = @nginx_conf.split('/').last
        @nginx_vhosts_dir = @nginx_conf_dir + '/sites-enabled'
      end

    end
  end
end