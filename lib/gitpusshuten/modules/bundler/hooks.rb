post "Install dependencies (Bundler)" do
  run "if [[ $(which bundle) == '' ]]; then gem install bundler; fi"
  run "bundle install --without development test"
end