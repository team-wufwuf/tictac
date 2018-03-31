require 'json'

module TicTac
  # TicTac Game Model
  module Models
    class GameModelError < StandardError
    end

    PRETTY_MAP = { 1 => 'x', -1 => 'o', 0 => ' ' }.freeze

    EMPTY_BOARD = [[0, 0, 0], [0, 0, 0], [0, 0, 0]].freeze

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
    }.freeze

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
    end.freeze

    def self.name
      'tic-tac-toe'
    end

    # board state nxn array of integers. 0 neutral. 1 crosses. -1 circles.
    # board status 'pending' 'in_play' 'crosses' (win) 'circles' (win) 'draw'
    class TicTacGame
      def initialize(args)
        board_to_load   = args[:board] || EMPTY_BOARD
        @rules          = args[:rules]
        @current_player = args[:current_player] || 1
        @state          = args[:state] || :pending

        @board = JSON.parse(JSON.dump(board_to_load))

        initial_setup(args)
      end

      def self.new_game(args)
        [
          [:board, 'New game on non-new board'],
          [:current_player, 'New game with defined current player'],
          [:state, 'New game with defined state']
        ].each do |invalid_key, msg|
          raise(GameModelError, msg) if args.key? invalid_key
        end

        raise(GameModelError, 'New game with no rules') unless args.key? :rules

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
              agg[k] = { player: (v == 1 ? 1 : 2) }
            end
          }
        )
      end

      attr_reader :board, :state, :current_player, :players, :rules

      def move(player_id, move)
        player = fetch_player(player_id)

        case state
        when :pending
          accept_game(player)
        when :accepted, :playing
          play(player, move)
        else
          raise GameModelError, 'GAME_OVER'
        end
      end

      def fetch_player(player_id)
        unless players.keys.include? player_id.to_sym
          raise GameModelError, 'INVALID_PLAYER'
        end
        players[player_id.to_sym]
      end

      def pretty_print
        board = @board.collect { |r| r.collect { |x| PRETTY_MAP[x] } }
        %(
        #{@state}
        _____
        #{pp_row(board[0])}
        #{pp_row(board[1])}
        #{pp_row(board[2])}
        -------
        #{@current_player}
        )
      end

      private

      def pp_row(row)
        "|#{row[0]}|#{row[1]}|#{row[2]}|"
      end

      attr_writer :board, :state, :current_player

      def accept_game(player)
        if player == current_player
          raise(GameModelError, 'WRONG_PLAYER_ACCEPTS')
        end
        raise(GameModelError, 'NOT_PENDING') if state != :pending

        # TODO: need some code to make sure the other player
        #   actually accepts.
        # it needs to be a message that is different each time but
        #   both players accept
        # so that it cannot be just repeated by a malicious player

        @current_player = players[player]
        @state = :accepted
      end

      def play(player, move)
        posx = move[:x]
        posy = move[:y]

        validate_move(player, posx, posy)

        board[posx][posy] = player
        @current_player = player
        @state = get_state(board)
      end

      def get_state(board)
        draw = true
        VICTORY_PATHS.each do |path|
          player1, player2 = check_victory_path(board, path)
          return :victory if player1 == 3 || player2 == 3
          draw = false if player1.zero? || player2.zero?
        end
        return :draw if draw
        :playing
      end

      def check_victory_path(board, path)
        players = { 1 => 0, -1 => 0, 0 => 0 }
        path.each do |idx|
          players[board[idx[0]][idx[1]]] += 1
        end
        [players[1], players[-1]]
      end

      def position_on_board?(posx, posy)
        posx <= 2 && posy <= 2 && posx >= 0 && posy >= 0
      end

      def validate_move(player, posx, posy)
        if !position_on_board?(posx, posy) || \
           @board[posx][posy] != 0 || \
           (player == current_player)
          raise GameModelError, 'INVALID_MOVE'
        end
      end
    end
  end
end
