require 'rubygems'
require 'sinatra'
Sinatra::Application.default_options.merge!(
  :run => false,
  :env => ENV['RACK_ENV']
)

require 'hotruby'

run Sinatra.application