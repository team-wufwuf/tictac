module TicTac
  module Models
    class GameModelError < StandardError
    end

    PRETTY_MAP = {1 => "x", -1 => "o", 0 => " "}

    EMPTY_BOARD = [[0, 0, 0], [0, 0, 0], [0, 0, 0]]

    LOOKUP_INDEX = {
      1 => [0, 0],
      2 => [0, 1],
      3 => [0, 2],
      4 => [1, 0],
      5 => [1, 1],
      6 => [1, 2],
      7 => [2, 0],
      8 => [2, 1],
      9 => [2, 2]
    }
      
    VICTORY_PATHS = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
      [1, 4, 7],
      [2, 5, 8],
      [3, 6, 9],
      [1, 5, 9],
      [3, 5, 7]
    ].map do |path|
      path.map { |i| LOOKUP_INDEX[i] }
    end

    # board state nxn array of integers. 0 neutral. 1 crosses. -1 circles.
    # board status 'pending' 'in_play' 'crosses' (win) 'circles' (win) 'draw'
    class TicTacGame

      def initialize(board=nil, current_player=1, state=:pending)
        @board = board || EMPTY_BOARD
        @current_player = current_player
        @state=state
      end

      attr_reader :board, :state, :current_player

      def accept_game(player)
        raise GameError.new('WRONG_PLAYER_ACCEPTS') if player == current_player
        raise GameError.new('NOT_PENDING') if state != :pending

        TicTacGame.new(board, player, :accepted)
      end

      def play(player, posx, posy)
        validate_move(player, posx, posy)

        new_board = @board.clone.tap { |b| b[posx][posy] = player }

        state = get_state(new_board)

        TicTacGame.new(new_board, player, state)
      end

      def get_state(b)
        draw = true
        VICTORY_PATHS.each do |path|
          player_1 = 0
          player_2 = 0
          path.each do |idx|
            val = b[*idx]
            if val == 1
              player_1 += 1
            elsif val == -1
              player_2 += 1
            end
          end
          if player_1 == 3 || player_2 == 3
            return :victory
          elsif player_1 == 0 || player_2 == 0
            draw = false
          end
        end
        return :draw if draw
        :playing
      end

      def validate_move(player, posx, posy)
        if x > 2 || y > 2 || x < 0 || y < 0 || @game_state[x][y] != 0 || (player == current_player)
          raise GameModelError.new("INVALID_MOVE")
        end
      end

      def self.name
        "tic-tac-toe"
      end

      def pretty_print
        x = @board.collect {|r| r.collect { |x| PRETTY_MAP[x] } }
        """
        _______
        |#{x.map{|y| y.join('|')}.join('|\n')}|
        -------
        """
      end
    end
  end
end

if __FILE__ == $0
  puts "yippee"
end
