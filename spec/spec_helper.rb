require 'gitpusshuten'

RSpec.configure do |config|
  config.mock_with :mocha
end


##
# GitPusshuTen::Command Mock
module GitPusshuTen
  module Commands
    class NonExistingCommand < GitPusshuTen::Commands::Base
      def initialize(cli, configuration, hooks, environment)
         super
         self
      end
      
      def perform!
        self
      end
    end
  end
end

def command_setup!(klass, argv)
  let(:configuration_file) { File.expand_path(File.dirname(__FILE__) + '/fixtures/config.rb')                           }
  let(:hooks_file)         { File.expand_path(File.dirname(__FILE__) + '/fixtures/hooks.rb')                            }
  
  let(:cli)                { GitPusshuTen::CLI.new(argv)                                                                }
  let(:configuration)      { GitPusshuTen::Configuration.new(cli.environment).parse!(configuration_file)                }
  let(:hooks)              { GitPusshuTen::Hooks.new(cli.environment, configuration_file).parse!(hooks_file)            }
  let(:environment)        { GitPusshuTen::Environment.new(configuration)                                               }
  let(:command)            { "GitPusshuTen::Commands::#{klass}".constantize.new(cli, configuration, hooks, environment) }
  let(:git)                { GitPusshuTen::Git.new                                                                      }
  
  before do
    command.stubs(:git).returns(git)
    git.stubs(:git)
  end
end