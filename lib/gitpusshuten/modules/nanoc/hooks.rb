##
# Post Deploy Hook for compiling the html files
# Checks if nanoc has been installed before attempting to compile
post "Compile HTML Files (Nanoc)" do
  run "if [[ -x $(which nanoc) ]]; then gem install nanoc; fi"
  run "rm -rf output public"
  run "nanoc compile"
  run "mv output public"
end