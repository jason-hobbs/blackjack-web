require 'rubygems'
require 'sinatra'

set :sessions, true




get '/' do
  if session['username']
    @username = session['username']
    erb :hometemplate
  else
    erb :form
  end
end


post '/getname' do
  session['username'] = params['username']
  redirect '/'
end
