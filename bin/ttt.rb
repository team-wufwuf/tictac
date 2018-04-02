require 'optparse'
require_relative '../lib/repos/game'

if $PROGRAM_NAME == __FILE__
  games = { 'tic-tac-toe' => TicTac::Models::TicTacGame }

  o = { game_class: games['tic-tac-toe'], data: nil, chain: nil, identity: 'self' }

  parser = OptionParser.new do |opts|
    opts.banner = 'Usage: game.rb [-g game_link] [-m move_data] [-o opponent] [-c game_class]'
    opts.on('-c', '--game-class', 'Only Tic Tac Toe works right now!') do |x|
      o[:game_class] = games[x]
    end
    opts.on('-g', '--game game', 'link to the head of the game you wanna make a move on') do |x|
      o[:game] = x
    end
    opts.on('-i', '--identity identity', 'ipfs name of the key that represents your player') do |x|
      o[:identity] = x
    end
    opts.on('-m', '--move move', 'Specified like 1,2 or "accept" for pending') do |x|
      if x == 'accept'
        o[:move] = { state: :accepted }
      else
        c = x.split(',')
        o[:move] = { x: c[0].to_i, y: c[1].to_i }
      end
    end
    opts.on('-o', '--opponent opponent', 'use this option to create a brand new game-- specify your opponents ipfs link address') do |x|
      o[:opponent] = x
    end
    opts.on('-i', '--identity identity', 'the name of your IPFS private key') do |x|
      o[:identity] = x
    end
  end

  parser.parse!
  id = TicTac::Identity.new(o[:identity])

  if o[:opponent]
    game = TicTac::Repos::GamePlayer.create(id, o[:opponent], o[:game_class])
    STDERR.puts game.pretty_print
    puts game.ipfs_addr
  elsif o[:move] && o[:game]
    game = TicTac::Repos::GamePlayer.new(o[:game])
    new_game = game.move(id, o[:move])
    STDERR.puts new_game.pretty_print
    puts new_game.ipfs_addr
  elsif o[:game]
    game = TicTac::Repos::GamePlayer.new(o[:game])
    STDERR.puts game.pretty_print
    puts game.ipfs_addr
  else
    puts parser.banner
  end
end
