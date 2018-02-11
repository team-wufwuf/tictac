require 'optparse'
require_relative '../appendlog.rb'
require_relative '../models/tic_tac_toe_game.rb'
require_relative '../identity.rb'
module TicTac
  module Repos
    User = Struct.new(:name, :pub_key)
    class GameError < StandardError
    end
    #
    class GamePlayer
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
          raise GamePlayerError.new("INVALID_PLAYERS")
        end
        #skip initial block, which is validated right here in this function (i hope)
        @chain[1..-1].each { |b|
          process_move(b.signer,b.data)
        }
      end
      def pretty_print
        @game.pretty_print
      end
      
      def self.create(id,opponent,game_class)
        @game=game_class.new
        chain=TicTac::Block.from_data(id,nil,{game: game_class.name,
                                              players:[opponent,id.public_key_link],
                                              state: @game.state
                                             }).ipfs_addr
        return GamePlayer.new(chain)
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
        @game.move(player,move)
      end
      def move(id,move)
        process_move(id.public_key_link,move)
        @chain=@chain.last.append(id,move)
        self
      end
    end
  end
end
