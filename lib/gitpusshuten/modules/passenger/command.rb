module GitPusshuTen
  module Commands
    class Passenger < GitPusshuTen::Commands::Base
      description "[Module] Phusion Passenger commands."
      usage       "passenger <command> for <environment>"
      example     "passenger install for staging    # Installs Passenger with the NginX web server"
      example     "passenger restart for production # Restarts the Passenger instance for the specified environment"

      ##
      # Passenger specific attributes/arguments
      attr_accessor :command

      ##
      # Initializes the Tag command
      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
      end

      ##
      # Performs the Passenger command
      def perform!
        if respond_to?("perform_#{command}!")
          send("perform_#{command}!")
        else
          GitPusshuTen::Log.error "Unknown RVM command: <#{y(command)}>"
          GitPusshuTen::Log.error "Run #{y('gitpusshuten help passenger')} for a list rvm commands."
        end
      end
      
      def perform_restart!
        GitPusshuTen::Log.message "Restarting Passenger for #{y(c.application)} (#{y(e.name)} environment)."
        environment.execute_as_user("cd #{e.app_dir}; mkdir -p tmp; touch tmp/restart.txt")
      end
      
      def perform_install!
        if not e.installed?('gem')
          GitPusshuTen::Log.error "Could not find RubyGems."
          GitPusshuTen::Log.error "Please install RVM (Ruby Version Manager) and at least one Ruby version."
          GitPusshuTen::Log.error "To do this, run: #{y("gitpusshuten rvm install for #{e.name}")}."
          exit
        end
        
        ##
        # Install the latest Passenger Gem
        Spinner.return :message => "Installing latest Phusion Passenger Gem.." do
          e.execute_as_root("gem install passenger --no-ri --no-rdoc")
          g("Done!")
        end
        
        ##
        # Install dependencies for Passenger
        Spinner.return :message => "Ensuring #{y('Phusion Passenger')} dependencies are installed.." do
          e.execute_as_root("aptitude update; aptitude install -y libcurl4-openssl-dev")
          g("Done!")
        end
        
        ##
        # Install Passenger (NginX Module) and NginX itself 
        GitPusshuTen::Log.message "Where would you like to install NginX? Provide an ABSOLUTE path."
        while @prefix.nil? or not @prefix =~ /^\//
          @prefix = ask("Leave empty if you want to use the default: /opt/nginx")
          @prefix = '/opt/nginx' if @prefix.empty?
        end
        
        GitPusshuTen::Log.standard "Installing #{y('Passenger')} with #{y('NginX')} (in #{y(@prefix)})"
        Spinner.return :message => "This may take a while.." do
          e.execute_as_root("passenger-install-nginx-module --auto --auto-download --prefix=#{@prefix}")
          g("Done!")
        end
        
        GitPusshuTen::Log.message "#{y('Passenger')} and #{y('NginX')} installed!"
      end

    end
  end
end