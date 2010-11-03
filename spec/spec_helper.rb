require 'gitpusshuten'

RSpec.configure do |config|
  config.mock_with :mocha
end


##
# GitPusshuTen::Command Mock
module GitPusshuTen
  module Commands
    class NonExistingCommand < GitPusshuTen::Commands::Base
      def initialize(cli, configuration, hooks, environment); self; end
      def perform!; self; end
    end
  end
end