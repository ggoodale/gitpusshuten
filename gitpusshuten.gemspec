Gem::Specification.new do |gem|

  gem.name        = 'gitpusshuten'
  gem.version     = '0.0.1'
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = 'Michael van Rooijen'
  gem.email       = 'meskyanichi@gmail.com'
  gem.homepage    = 'http://gitpusshuten.com/'
  gem.summary     = 'Heavenly Git-based Application Deployment.'
  gem.description = 'A Git-based application deployment tool that allows you to define your environment
                    by utilizing modules and provision your server with basic deployment needs.'

  gem.files         = %x[git ls-files].split("\n")
  gem.test_files    = %x[git ls-files -- {spec}/*].split("\n")
  gem.require_path  = 'lib'
  
  gem.executables   = ['gitpusshuten', 'heavenly', 'ten']
  
  gem.add_dependency 'rainbow',       ['~> 1.1.0']
  gem.add_dependency 'highline',      ['~> 1.6.0']
  gem.add_dependency 'net-ssh',       ['~> 2.0.0']
  gem.add_dependency 'net-scp',       ['~> 1.0.0']
  gem.add_dependency 'activesupport', ['~> 3.0.0']
  gem.add_dependency 'json',          ['~> 1.4.0']

end