Gem::Specification.new do |gem|
  gem.name        = 'gitpusshuten'
  gem.version     = '0.0.1'
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = 'Michael van Rooijen'
  gem.email       = 'meskyanichi@gmail.com'
  gem.homepage    = 'http://rubygems.org/gems/gitpusshuten'
  gem.summary     = 'Heavenly Application Deployment.'
  gem.description = 'Heavenly Application Deployment.'

  gem.files         = %x[git ls-files].split("\n")
  gem.test_files    = %x[git ls-files -- {spec}/*].split("\n")
  gem.require_path  = 'lib'
  
  gem.executables   = ['gitpusshuten', 'pusshu', 'push']
  
  gem.add_dependency 'rainbow',       ['~> 1.1.0']
  gem.add_dependency 'highline',      ['~> 1.6.0']
  gem.add_dependency 'net-ssh',       ['~> 2.0.0']
  gem.add_dependency 'net-scp',       ['~> 1.0.0']
  gem.add_dependency 'activesupport', ['~> 3.0.0']
  gem.add_dependency 'json',          ['~> 1.4.0']

end