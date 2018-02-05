require 'optparse'
require_relative '../lib/repos/game'

if __FILE__ == $0
  games={"tic-tac-toe" => TicTac::Models::TicTacGame}
  o={game_class: games["tic-tac-toe"] ,data: nil, chain: nil,identity: "self"}
  parser=OptionParser.new do |opts|
    opts.banner = "Usage: game.rb [-g game_link] [-m move_data] [-o opponent] [-c game_class]"
    opts.on('-c', '--game-class', 'Only Tic Tac Toe works right now!')  {|x| o[:game_class] = games[x] }
    opts.on('-g', '--game game', 'link to the head of the game you wanna make a move on')  {|x| o[:game] = x }
    opts.on('-i', '--identity identity', 'ipfs name of the key that represents your player')  {|x| o[:identity] = x }
    opts.on('-m','--move move','Specified like 1,2 or "accept" for pending') do |x|
      if x == "accept"
        o[:move]={state: :accepted}
      else
        c=x.split(",")
        o[:move] = {x: c[0].to_i, y: c[1].to_i }
      end
    end
    opts.on('-o','--opponent opponent') {|x| o[:opponent]=x }
    opts.on('-i','--identity identity') {|x| o[:identity]=x }
  end
  parser.parse!
  id=TicTac::Identity.new(o[:identity])
  
  if o[:opponent]
    game= TicTac::Repos::Game.create(id,o[:opponent],o[:game_class])
    STDERR.puts game.pretty_print
    puts game.ipfs_addr
  elsif o[:move] && o[:game]
    game=TicTac::Repos::Game.new(o[:game])
    new_game=nil
    new_game=game.move(id,o[:move])
    STDERR.puts new_game.pretty_print
    puts new_game.ipfs_addr
  elsif o[:game]
    game=TicTac::Repos::Game.new(o[:game])
    STDERR.puts game.pretty_print
    puts game.ipfs_addr
  else
    puts parser.banner
  end

end
