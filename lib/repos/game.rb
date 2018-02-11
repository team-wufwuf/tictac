require 'forwardable'
require_relative '../appendlog.rb'
require_relative '../models/tic_tac_toe_game.rb'
require_relative '../identity.rb'

module TicTac
  module Repos
    User = Struct.new(:name, :pub_key)

    class GameError < StandardError
    end

    class Games
      extend Forwardable

      attr_reader :ipfs_addr, :game_status, :winner, :chain

      # later this will be generated through introspection, so use the snakecase
      #   version of the game name
      Games = {"tic_tac_game" => TicTac::Models::TicTacGame}

      def initialize(ipfs_addr)
        @ipfs_addr = ipfs_addr

        @chain = TicTac::Block.new(ipfs_addr).get_chain

        initblock = chain.first

        signer = initblock.signer
        rules  = initblock.data

        game = Games[rules[:game]].new_game(rules)

        #skip initial block, which is validated right here in this function (i hope)
        @chain[1..-1].each { |b|
          process_move(b.signer, b.data)
        }
      end

      def pretty_print
        @game.pretty_print
      end

      # user: TicTac::Repos::User
      def self.create(id, opponent, game_class)
        @game=game_class.new
        chain = TicTac::Block.from_data(
          id,
          nil,
          {
            game:    game_class.name,
            players: [opponent, id.public_key_link],
            board:   @game.board
          }
        ).ipfs_addr

        new(chain)
      end

      def get_player_index(ipfs_link)
        if @players.has_key? 
          raise GameError.new("INVALID_PLAYER")
        end
        @players[ipfs_link]
      end

      def process_move(player_key, move)
        player = get_player_index(player_key)
        game.move(move)
      end
    end
  end
end
