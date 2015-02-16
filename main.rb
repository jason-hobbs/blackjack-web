require 'rubygems'
require 'sinatra'

set :sessions, true




get '/' do
  if session['username']
    redirect '/game'
  else
    erb :form
  end
end


post '/getname' do
  session['username'] = params['username']
  redirect '/'
end

get '/game' do
  if session['username']
    suits = ['Hearts', 'Diamonds', 'Spades', 'Clubs']
    values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace']
    session[:deck] = suits.product(values).shuffle!
    session[:dealer_cards] = []
    session[:player_cards] = []
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
    session[:player_cards] << session[:deck].pop
    erb :game
  else
    redirect '/'
  end
end
