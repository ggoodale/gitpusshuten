module GitPusshuTen
  module Commands
    class Rvm < GitPusshuTen::Commands::Base
      description "Install RVM (Ruby Version Manager) on the remote server."
      usage       "rvm <command> for <environment>"
      example     "rvm install for staging"

      ##
      # Passenger specific attributes/arguments
      attr_accessor :command

      ##
      # Initializes the RVM command
      def initialize(*objects)
        super
        
        @command = cli.arguments.shift
        
        help if command.nil? or e.name.nil?
      end

      ##
      # Performs the RVM command
      def perform!
        if respond_to?("perform_#{command}!")
          send("perform_#{command}!")
        else
          GitPusshuTen::Log.error "Unknown RVM command: <#{y(command)}>"
          GitPusshuTen::Log.error "Run #{y('gitpusshuten help rvm')} for a list rvm commands."
        end
      end

      def perform_install!
        GitPusshuTen::Log.message "Installing #{y('RVM')} (System Wide)!"
        
        ##
        # Update apt-get and install git/curl/wget
        puts "updating apt-get and installing git curl wget"
        e.execute_as_root("apt-get update; apt-get install -y git-core curl wget;")
        
        ##
        # Install RVM (system wide)
        puts "installing rvm system wide"
        e.execute_as_root("bash < <( curl -L http://bit.ly/rvm-install-system-wide )")
        
        ##
        # Download Git Packages and add the rvm load snippet into /etc/profile
        puts "downloading gitpusshuten packages, configuring /etc/profile"
        e.download_packages!("$HOME", :root)
        e.execute_as_root("cd $HOME; cat gitpusshuten-packages/modules/rvm/profile >> /etc/profile")
        e.clean_up_packages!("$HOME", :root)
        
        ##
        # Create a .bashrc in $HOME to load /etc/profile for non-interactive sessions
        puts "Create or Append root's .bashrc file to load /etc/profile for non-interactive sessions"
        e.execute_as_root("echo 'source /etc/profile' >> $HOME/.bashrc; source $HOME/.bashrc")
        
        ##
        # Install required packages for installing Ruby
        puts "installing ruby interpreter dependency packages with aptitude"
        e.execute_as_root("aptitude install -y build-essential bison openssl libreadline5 libreadline5-dev curl git zlib1g zlib1g-dev libssl-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev")
        
        ##
        # Install a Ruby version
        puts "Installing ruby 1.9.2"
        e.execute_as_root("rvm install 1.9.2")
        
        ##
        # Set the Ruby version as the default Ruby
        puts "setting ruby 1.9.2 as the default ruby"
        e.execute_as_root("rvm use 1.9.2 --default")
      end
      
    end
  end
end