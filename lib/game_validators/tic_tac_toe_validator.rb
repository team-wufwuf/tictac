module TicTac
  module GameValidator
    class TicTacToeValidator < Base
      turn do |state, turn|
        return initialize_game if state.nil?
        return accept_game(state, turn) if state.board_state == :pending
        state.play(turn.player, turn.x, turn.y)
      end

      def initialize_game
        TicTic::Models::TicTacGame.new
      end

      def accept_game(state, turn)
        state.accept_game(turn.player)  
      end
    end
  end
end
  
