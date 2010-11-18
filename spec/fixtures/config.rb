pusshuten 'RSpec Staging Example Application', :staging do
  
  configure do |c|
    c.user        = 'git'
    c.password    = 'testtest'
    c.passphrase  = 'myphrase'
    c.ip          = '123.45.678.910'
    c.port        = '20'
    
    c.path        = '/var/apps/'
  end
  
  modules do |m|
    m.add :nginx
    m.add :passenger
    m.add :active_record
  end
  
end

pusshuten 'RSpec Production Example Application', :production do
  
end