##
# Post Deploy Hook for installing gems
# Checks if the bundle command is available before attemping
# and installs the Bundler gem if it is not available before proceeding
post "Install dependencies (Bundler)" do
  run "if [[ $(which bundle) == '' ]]; then gem install bundler; fi"
  run "bundle install --without development test"
end