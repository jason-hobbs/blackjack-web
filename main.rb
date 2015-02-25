require 'rubygems'
require 'sinatra'

set :sessions, true
set :root, File.dirname(__FILE__)

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
INITIAL_POT_AMOUNT = 500

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
      break if total <= BLACKJACK_AMOUNT
      total -= 10
    end

    total
  end

  def loser(message)
    @show_hit_or_stay_buttons = false
    session[:pot] = session[:pot] - session[:bet]
    @loser = message
    @play_again = true
  end

  def winner(message)
    @show_hit_or_stay_buttons = false
    session[:pot] = session[:pot] + session[:bet]
    @winner = message
    @play_again = true
  end

  def tie(message)
    @show_hit_or_stay_buttons = false
    @winner = message
    @play_again = true
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:username]
    redirect '/bet'
  else
    erb :form
  end
end

post '/getname' do
  if params['username'].empty?
    @error = "Name is required"
    halt erb(:form)
  else
    session[:username] = params['username']
    session[:pot] = INITIAL_POT_AMOUNT
    redirect '/bet'
  end
end

get '/bet' do
  session[:bet] = nil
  erb :bet
end

get '/new' do
  session[:username] = nil
  session[:pot] = nil
  redirect '/'
end

post '/bet' do
  if params[:bet].nil? || params[:bet].to_i == 0
    @error = "Must make a bet."
    halt erb(:bet)
  elsif params[:bet].to_i > session[:pot]
    @error = "You bet more than you have! ($#{session[:pot]})"
    halt erb(:bet)
  else
    session[:bet] = params[:bet].to_i
    redirect '/game'
  end
end

get '/game' do
  if session[:username]
    unless session[:pot]
      session[:pot] = INITIAL_POT_AMOUNT
    end
    session[:turn] = session[:username]
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
  if player_total == BLACKJACK_AMOUNT
    winner("Congratulations! #{session[:username]} hit blackjack!")
  elsif player_total > BLACKJACK_AMOUNT
    loser("#{session[:username]} busted with #{player_total}!")
  end
  erb :game, layout: false
end

post '/game/player/stay' do
  @success = "#{session[:username]} has chosen to stay."
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == BLACKJACK_AMOUNT
    loser("Sorry, dealer hit blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner("Congratulations! Dealer busted with #{dealer_total}!  #{session[:username]} wins!")
  elsif dealer_total >= DEALER_MIN_HIT
    #dealer stays
    redirect '/game/compare'
  else
    #dealer hits
    @show_hit_or_stay_buttons = false
    @show_dealer_hit_button = true
  end
  erb :game, layout: false
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  if player_total < dealer_total
    #@error = "Sorry, #{session[:username]} lost.  Dealer wins with #{dealer_total}."
    loser("Sorry, #{session[:username]} lost.  Dealer wins with #{dealer_total}.")
  elsif player_total > dealer_total
    #@success = "Congratulations! #{session[:username]} wins!"
    winner("Congratulations! #{session[:username]} wins with #{player_total}!")
  else
    tie("Game ended in a tie.")
  end
  erb :game, layout: false
end

get '/game_over' do
  erb :game_over
end
