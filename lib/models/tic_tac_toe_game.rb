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

      def initialize(args)
        board_to_load   = args[:board]          || EMPTY_BOARD
        @rules          = args[:rules]
        @current_player = args[:current_player] || 1
        @state          = args[:state]          || :pending


      def pretty_print
        x=@board.collect {|r| r.collect { |x| PRETTY_MAP[x] } }
        """
        #{@state}
        _____
        |#{x[0][0]}|#{x[1][0]}|#{x[2][0]}|
        |#{x[0][1]}|#{x[1][1]}|#{x[2][1]}|
        |#{x[0][2]}|#{x[1][2]}|#{x[2][2]}|
        -------
        #{@current_player}
        """
      end
        @board = JSON.load(JSON.dump(board_to_load))

        initial_setup(args)
      end

      def self.new_game(args)
        raise GameModelError("New game on non-new board")            if args.has_key?  :board
        raise GameModelError("New game with defined current player") if args.has_key?  :current_player
        raise GameModelError("New game with defined state")          if args.has_key?  :state
        raise GameModelError("New game with no rules")               if !args.has_key? :rules

        new(args)
      end

      def initial_setup(args)
        @players = args[:rules][:players].each_with_object({}) do |(k, v), agg|
          agg[k] = (v[:player] == 1 ? 1 : -1)
        end
      end

      def clone
        TicTacGame.new(
          board: board,
          current_player: current_player,
          state: state,
          rules: {
            players: players.each_with_object({}) do |(k, v), agg|
              agg[k] = {player: (v == 1 ? 1 : 2)}
            end
          }
        )
      end

      attr_reader :board, :state, :current_player, :players, :rules

      def move(move)
        player = move[:player]

        raise GameModelError.new("INVALID_PLAYER") unless players.keys.include? player

        if state == :pending
          accept_game(player)
        elsif state == :accepted || state == :playing
          play(move)
        else
          raise GameModelError('GAME_OVER')
        end
      end

      def pretty_print
        x=@board.collect {|r| r.collect { |x| PRETTY_MAP[x] } }
        """
        #{@state}
        _____
        |#{x[0][0]}|#{x[1][0]}|#{x[2][0]}|
        |#{x[0][1]}|#{x[1][1]}|#{x[2][1]}|
        |#{x[0][2]}|#{x[1][2]}|#{x[2][2]}|
        -------
        #{@current_player}
        """
      end

      private

      attr_writer :board, :state, :current_player

      def accept_game(player)
        raise GameModelError.new('WRONG_PLAYER_ACCEPTS') if player == current_player
        raise GameModelError.new('NOT_PENDING')          if state  != :pending

        # TODO: need some code to make sure the other player actually accepts.
        # it needs to be a message that is different each time but both players accept
        # so that it cannot be just repeated by a malicious player
        
        @current_player = players[player]
        @state = :accepted
      end

      def play(move)
        player = players[move[:player]]

        posx = move[:x]
        posy = move[:y]

        validate_move(player, posx, posy)

        board[posx][posy] = player
        @current_player = player
        @state = get_state(board)
      end

      def get_state(b)
        draw = true
        VICTORY_PATHS.each do |path|
          player_1 = 0
          player_2 = 0
          path.each do |idx|
            val = b[idx[0]][idx[1]]
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
      
      def validate_move(player, x, y)
        if x > 2 || y > 2 || x < 0 || y < 0 || @board[x][y] != 0 || (player == current_player)
          raise GameModelError.new("INVALID_MOVE")
        end
      end

      def self.name
        "tic-tac-toe"
      end
    end
  end
end

if __FILE__ == $0
  puts "yippee"
end
