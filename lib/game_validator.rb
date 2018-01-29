# describes a game rule validator for a simple game
# create a class like
# class TicTacToeValidator < TicTac::GameValidator::Base
#   validate_turn do |state, turn|
#       validate_rules_and_players if state.nil?
#       validate_move(state, turn.move)....


module TicTac
  module GameValidator
    class Base
      def call(game_tree)
        game_tree.reduce(nil) do |state, turn|
          turn_validator.(state, turn)
        end
      end

      def turn_validator
        self.class.turn_validator
      end

      class << self
        def validate_turn(&block)
          @turn_validator = block
        end

        attr_reader :turn_validator
      end
    end
  end
end
