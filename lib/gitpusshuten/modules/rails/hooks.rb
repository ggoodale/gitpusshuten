##
# Will check if the Rails.root/config/database.yml.<environment> exists
# if it does, it'll overwrite the database.yml with that environment database.
# If it does not exist, it'll leave the database.yml unchanged.
post "Setting proper database for environment. (Rails)" do
  run "if [[ -f 'config/database.yml.#{environment}' ]]; then " +
      "echo 'config/database.yml.#{environment} found! Overwrite it over database.yml.';" +
      "mv 'config/database.yml.#{environment}' 'config/database.yml'; " +
      "fi"
end