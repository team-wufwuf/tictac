module TicTac
  module GameValidator
    class TicTacToeValidator < Base
      validate_turn do |state, turn|
        return initialize_game(turn) if state.nil?
        return accept_game(turn) if state.board_state == 'pending'
        model.play(turn.player, turn.x, turn.y)
        model
      end

      def initialize_game(turn)
      end

      def accept_game(turn)
      end
    end
  end
end
  
