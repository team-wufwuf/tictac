require_relative 'tictac'
require_relative 'appendlog'

module TicTac
  class TicTacToeBoard
    #reference implementation of a simple game.
    def initialize(ipfs_addr)
      @chain=Block.new(ipfs_addr).get_chain
    end
    def is_valid?
      block=@chain.first
      #return true
    end
    def make_play(x,y)
      @chain.last.append({x: x,y: y})
    end
  end
end
