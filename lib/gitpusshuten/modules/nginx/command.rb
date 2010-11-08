module GitPusshuTen
  module Commands
    class Nginx < GitPusshuTen::Commands::Base
      description "[module] Enables various NGINX commands."
      usage       "nginx <command> for <environment>"
      example     "nginx start for staging"
      example     "nginx stop for staging"
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
      end

      ##
      # Performs the Passenger command
      def perform!        
        if respond_to?("perform_#{command}!")
          send("perform_#{command}!")
        else
          GitPusshuTen::Log.error "Unknown Nginx command: <#{object}>"
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
      # Installs the Nginx executable if it does not exist
      def ensure_nginx_executable_is_installed!
        if not environment.file?("/etc/init.d/nginx")
          GitPusshuTen::Log.message "Installing Nginx executable for starting/stopping/restarting/reloading Nginx."
          environment.download_gitpusshuten_packages!
          environment.execute_as_root("cp '#{File.join(environment.packages_dir, 'modules', 'nginx', 'nginx')}' /etc/init.d/nginx")
          environment.clean_up_gitpusshuten_packages!
        end
      end

    end
  end
end