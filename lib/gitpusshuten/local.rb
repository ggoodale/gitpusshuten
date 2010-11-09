module GitPusshuTen
  class Local
    
    ##
    # Performs a command on the local machien
    def execute(command)
      %x[#{command}]
    end
    
    ##
    # Returns the .gitpusshuten local directory
    def gitpusshuten_dir
      File.join(Dir.pwd, '.gitpusshuten')
    end

    ##
    # Returns the .gitpusshuten tmp directory
    def tmp_dir
      File.join(gitpusshuten_dir, 'tmp')
    end

    ##
    # Create tmp_dir
    def create_tmp_dir!
      %x[mkdir -p '#{tmp_dir}']
    end

    ##
    # Removes everything inside the tmp_dir
    def remove_tmp_dir!
      %x[rm -rf '#{tmp_dir}']
    end

  end
end