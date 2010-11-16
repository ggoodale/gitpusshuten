##
# Will check if the app_root/config/database.yml.<environment> exists
# if it does, it'll overwrite the database.yml with that environment database.
# If it does not exist, it'll leave the database.yml unchanged.
post "Setting proper database for environment. (Rails)" do
  run "if [[ -f 'config/database.yml.#{environment}' ]]; then " +
      "echo 'config/database.yml.#{environment} found! Using this one instead of config/database.yml';" +
      "echo 'Overwriting config/database.yml with config/database.yml.#{environment}';" +
      "mv 'config/database.yml.#{environment}' 'config/database.yml'; " +
      "fi"
end

##
# Will create the database if it doesn't exist yet.
# Migrates the database.
post "Migrate Database (Active Record)" do
  run "rake db:create"
  run "rake db:migrate"
end