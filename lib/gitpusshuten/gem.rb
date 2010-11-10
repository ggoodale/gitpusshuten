module GitPusshuTen
  class Gem

    ##
    # Stores the JSON gem object from RubyGems.org
    attr_accessor :gem

    ##
    # Instantiages a new gem
    def initialize(name)
      @gem = JSON.parse(open(File.join(base_url, "#{name}.json")).read)
    end

    ##
    # Returns the latest version of the gem
    def latest_version
      gem['version']
    end

    ##
    # Checks to see if the provided version number is outdated
    def outdated?(version)
      version < latest_version
    end

    ##
    # Returns the base url to the RubyGems API
    def base_url
      "http://rubygems.org/api/v1/gems/"
    end

  end
end