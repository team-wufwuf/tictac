require_relative '../models/tic_tac_toe_game'
module TicTac
  module Repos
    User = Struct.new(:name, :pub_key)

    class GameError < StandardError
    end

    # provides CRUD for tic tac toe games
    class GameRepo
      class << self
        attr_accessor :block_adapter, :publisher
      end

      # later this will be generated through introspection, so use the snakecase
      #   version of the game name
      GAME_LOOKUP = { 'tic-tac-toe' => TicTac::Models::TicTacGame }.freeze

      def self.read_game(ipfs_addr)
        block = block_adapter.new(ipfs_addr)
        [block, block_to_game(block)]
      end

      def self.add_move_to_game(block, identity, move)
        game = block_to_game(block)

        game.move(identity.public_key_link, move)

        new_block = block.append(identity, move)

        publisher.publish(new_block.ipfs_addr)

        [new_block, game]
      end

      def self.block_to_game(block)
        chain = block.get_chain

        initblock = chain.first

        rules = initblock.data[:rules]

        GAME_LOOKUP[rules[:game]].new_game(initblock.data).tap do |g|
          chain[1..-1].each do |b|
            g.move(b.signer, b.data)
          end
        end
      end
    end
  end
end
