require 'optparse'
require_relative '../lib/repos/game'
require_relative '../lib/ipfs/identity'
require_relative '../lib/ipfs/block'
require_relative '../lib/ipfs/pubsub'
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
  TicTac::Repos::GameRepo.block_adapter = Ipfs::Block

  id = Ipfs::Identity.new(o[:identity]) unless !o[:identity]
  TicTac::Repos::GameRepo.publisher = Ipfs::Publisher.new(id.public_key_link)
  #TODO: distinguish between keynames and key links
  opponent = Ipfs::Identity.new(o[:opponent]) unless !o[:opponent]

  #start a new game
  if o[:opponent] && o[:identity]

    print o[:game_class].name
    game = {rules: {game: o[:game_class].name,players: {id.public_key_link.to_sym => {player: 1},
                                                        opponent.public_key_link.to_sym => {player: 2}}}}
    STDERR.puts TicTac::Repos::GameRepo.new_game(game).pretty_print
    block=Ipfs::Block.from_data(id,nil,game)
    puts block.ipfs_addr

  #make a move in an existing game
  elsif o[:move] && o[:game]
    block,game = TicTac::Repos::GameRepo.read_game(o[:game])
    new_block,game = TicTac::Repos::GameRepo.add_move_to_game(block,id,o[:move])
    puts game.pretty_print
    puts new_block.ipfs_addr
  #view an existing game
  elsif o[:game]
    block,game = TicTac::Repos::GameRepo.read_game(o[:game])
    STDERR.puts game.pretty_print
    puts block.ipfs_addr
  else
    puts parser.banner
  end
end
