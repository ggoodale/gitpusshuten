# encoding: utf-8

module GitPusshuTen
  class Command

    ##
    # Contains an array of blacklisted commands
    # These are files that aren't actually CLI commands but just
    # classes that are used by Git プ ッ シ ュ 天
    BLACKLISTED = %w[base]

    ##
    # Command-line Interface
    attr_accessor :cli

    ##
    # Configuration (Environment)
    attr_accessor :configuration

    ##
    # Contains pre/post-deployment hooks
    attr_accessor :hooks

    ##
    # Environment connection
    attr_accessor :environment

    ##
    # Initializes the specified command if it exists or
    # errors out when it does not exist in the commands/*.rb
    def initialize(cli, configuration, hooks, environment)
      @cli           = cli
      @configuration = configuration
      @hooks         = hooks
      @environment   = environment
      
      if cli.command.nil?
        display_commands
        exit
      end
      
      unless available_commands.include?(cli.command)
        GitPusshuTen::Log.error "Command <#{cli.command.color(:red)}> not found."
        exit
      end
    end

    ##
    # Performs the target command, based on the CLI and Configuration
    def perform!
      %w[validate! pre_perform! perform! post_perform!].each do |action|
        command.send(action)
      end
    end

    ##
    # Wrapper for the command instance
    def command
      @command ||= "GitPusshuTen::Commands::#{cli.command.classify}".constantize.new(cli, configuration, hooks, environment)
    end

    ##
    # Returns an array of available commands
    def available_commands
      commands = commands_directory.map do |command|
        unless blacklisted?(command)
          find(command)
        end
      end
      
      if configuration.respond_to?(:additional_modules)
        module_directory.each do |command|
          configuration.additional_modules.each do |additional_module|
            if command =~ /\/modules\/(#{additional_module})\/command\.rb/
              commands << $1
            end
          end
        end
      end
      
      commands.flatten.compact.uniq
    end

    ##
    # Returns the absolute path to each command (ruby file)
    # insidethe commands directory and returns an array of each entry
    def commands_directory
      Dir[File.expand_path(File.join(File.dirname(__FILE__), 'commands/*.rb'))]
    end

    def module_directory
      Dir[File.expand_path(File.join(File.dirname(__FILE__), 'modules', '*', 'command.rb'))]
    end

    ##
    # Determines whether the provided command is blacklisted or not
    def blacklisted?(command)
      BLACKLISTED.include?(find(command))
    end

    ##
    # Expects a (full) path to the command ruby file and returns
    # only the file name without the .rb extension
    def find(command)
      command.gsub(/\.rb/, '').split('/').last
    end

    ##
    # Displays a list of available commands in the CLI
    def display_commands
      puts "\nGit Pusshu Ten\n\s\s\s\sプッシュ点\n\n"
      puts "[Alias]\n\n"
      puts "\s\s#{y('ten')}\n\n"
      puts "[Commands]\n\n"
      available_commands.compact.sort.each do |command|
        puts "\s\s" + y(command) + (command.length < 6 ? "\t" : "") + "\t" + get_constant_for(command).description          
      end
      puts "\n[Command Specific Help]\n\n" + "\s\sgitpusshuten help <command>\n".color(:yellow)
      puts "For more information, visit: #{y 'http://gitpusshuten.com/'}"
    end

    ##
    # Displays command specific details in the CLI
    def display_usage(command)
      puts "\nGit Pusshu Ten\n\s\s\s\sプッシュ点\n\n"
      puts "[Command]\n\n\s\s#{y(command)}\n\n"
      puts "[Description]\n\n\s\s#{get_constant_for(command).description}\n\n"
      puts "[Usage]\n\n\s\s#{y get_constant_for(command).usage}\n\n"
      puts "[Examples]\n#{get_constant_for(command).example}\n\n"
      puts "For a list of all commands: #{y 'gitpusshuten help'}"
      puts "For more information, visit: #{y 'http://gitpusshuten.com/'}"
    end

    ##
    # Returns the constant of a command
    def get_constant_for(command)
      "GitPusshuTen::Commands::#{command.classify}".constantize
    end

    ##
    # Wrapper for coloring text yellow
    def y(value)
      value.to_s.color(:yellow)
    end

  end
end
