require 'rubygems'
require 'sinatra'

set :sessions, true
set :root, File.dirname(__FILE__)

helpers do
  def calculate_total(cards)
    arr = cards.map{|element| element[1]}
    total=0
    arr.each do |a|
      if a == 'Ace'
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    arr.select{|element| element == 'Ace'}.count.times do
      break if total <= 21
      total -= 10
    end

    total
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session['username']
    redirect '/game'
  else
    erb :form
  end
end

post '/getname' do
  if params['username'].empty?
    @error = "Name is required"
    halt erb(:form)
  else
    session['username'] = params['username']
    redirect '/'
  end
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

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == 21
    @success = "Congratulations! #{session[:username]} hit blackjack!"
    @show_hit_or_stay_buttons = false
  elsif player_total > 21
    @error = "#{session[:username]} busted!"
    @show_hit_or_stay_buttons = false
  end
  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:username]} has chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  @show_hit_or_stay_buttons = false
  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == 21
    @error = 'Sorry, dealer hit blackjack.'
  elsif dealer_total > 21
    @success = "Congratulations! Dealer busted with #{dealer_total}!  #{session[:username]} wins!"
  elsif dealer_total >= 17
    #dealer stays
    redirect '/game/compare'
  else
    #dealer hits
    @show_dealer_hit_button = true
  end
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  if player_total < dealer_total
    @error = "Sorry, #{session[:username]} lost.  Dealer wins with #{dealer_total}."
  elsif player_total > dealer_total
    @success = "Congratulations! #{session[:username]} wins!"
  else
    @success = "Game ended in a tie."
  end
  erb :game
end
