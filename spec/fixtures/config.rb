pusshuten 'RSpec Staging Example Application', :staging do
  
  authorize do |a|
    a.user        = 'git'
    a.password    = 'testtest'
    a.passphrase  = 'myphrase'
    a.ip          = '123.45.678.910'
    a.port        = '20'
  end
  
  applications do |a|
    a.path = '/var/apps/'
  end
  
  modules do |m|
    m.add :nginx
    m.add :passenger
    m.add :active_record
  end
  
end

pusshuten 'RSpec Production Example Application', :production do
  
end