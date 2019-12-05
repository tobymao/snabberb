# frozen_string_literal: true

require 'bundler'
Bundler.require

# Instructions: bundle in this directory
# then run `bundle exec rackup` to start the server
# and browse to http://localhost:9292

# the directory where the code is (add to opal load path )
Opal.append_path('app')

run(Opal::SimpleServer.new do |s|
  # the name of the ruby file to load. To use more files they must be required from here (see app)
  s.main = 'application'
  # need to set the index explicitly for opal server to pick it up
  s.index_path = 'index.html.erb'
end)
