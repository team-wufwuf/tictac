require_relative '../appendlog.rb'
require_relative '../models/tic_tac_toe_game.rb'
require_relative '../identity.rb'

module TicTac
  module Repos
    User = Struct.new(:name, :pub_key)

    class GameError < StandardError
    end

    class GameRepo

      class << self
        attr_accessor :block_adapter, :publisher
      end

      # later this will be generated through introspection, so use the snakecase
      #   version of the game name
      GameLookup = {"tic_tac_game" => TicTac::Models::TicTacGame}

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

      private

      def self.block_to_game(block)
        chain = block.get_chain

        initblock = chain.first

        signer = initblock.signer

        rules = initblock.data[:rules]

        game = GameLookup[rules[:game]].new_game(initblock.data).tap do |g|
          chain[1..-1].each do |b|
            g.move(b.signer, b.data)
          end
        end
      end
    end
  end
end
