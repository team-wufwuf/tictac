require 'optparse'
require_relative '../appendlog.rb'
require_relative '../models/tic_tac_toe_game.rb'
require_relative '../identity.rb'
module TicTac
  module Repos
    User = Struct.new(:name, :pub_key)
    class GameError < StandardError
    end
    class Game
      attr_reader :ipfs_addr,:game_status,:winner,:chain
      Games = {"tic-tac-toe" => TicTac::Models::TicTacGame}
      def initialize(ipfs_addr)
        @ipfs_addr = ipfs_addr
        @chain=TicTac::Block.new(ipfs_addr).get_chain
        @initblock=@chain.first
        @signer=@initblock.signer
        @rules=@initblock.data
        @players=@rules[:players]
        @game=Games[@rules[:game]].new
        if !@rules[:players].include?(@signer) || !@rules[:players][0] || !@rules[:players][1]
          raise GameError.new("INVALID_PLAYERS")
        end
        #skip initial block, which is validated right here in this function (i hope)
        @chain[1..-1].each { |b|
          process_move(b.signer,b.data)
        }
      end
      def pretty_print
        @game.pretty_print
      end
      # user: TicTac::Repos::User
      def self.create(id,opponent,game_class)
        @game=game_class.new
        chain=TicTac::Block.from_data(id,nil,{game: game_class.name,
                                              players:[opponent,id.public_key_link],
                                              state: @game.state
                                             }).ipfs_addr
        return Game.new(chain)
      end
      def get_player_index(ipfs_link)
        idx=@players.index(ipfs_link)
        if !idx
          raise GameError.new("INVALID_PLAYER")
        end
        idx
      end
      def process_move(player_key,move)
        player=get_player_index(player_key)
        @game=@game.move(player,move)
      end
      def move(id,move)
        process_move(id.public_key_link,move)
        @game=Game.new(@chain.last.append(id,move).ipfs_addr)
      end
      def get(name: nil, pub_key: nil)
        # find matching user, return User object.
      end
    end
  end
end
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
  puts o.inspect
  id=TicTac::Identity.new(o[:identity])
  
  if o[:opponent]
    game= TicTac::Repos::Game.create(id,o[:opponent],o[:game_class])
    puts game.pretty_print
    puts game.ipfs_addr
  elsif o[:move] && o[:game]
    game=TicTac::Repos::Game.new(o[:game])
    new_game=nil
    require 'pry'
    binding.pry
    new_game=game.move(id,o[:move])
    puts new_game.pretty_print
    puts new_game.ipfs_addr
  elsif o[:game]
    game=TicTac::Repos::Game.new(o[:game])
    puts game.pretty_print
    puts game.ipfs_addr
  else
    puts parser.banner
  end

end
