require 'rubygems'
require 'sinatra'

set :sessions, true




get '/' do
  erb :form
end


post '/getname' do
  puts params['username']
end
