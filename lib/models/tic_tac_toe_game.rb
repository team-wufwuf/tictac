module TicTac
  module Models
    class GameModelError < StandardError
    end
    # board state nxn array of integers. 0 neutral. 1 crosses. -1 circles.
    # board status 'pending' 'in_play' 'crosses' (win) 'circles' (win) 'draw'
    attr_accessor :game_status, :game_state
    class TicTacGame
      def initialize(game_state,game_status)
        @game_status,@game_state=game_status,game_state
      end
      def self.name
        "tic-tac-toe"
      end
      def move(player,x,y)
        if x > 2 or y > 2 or @game_state[x][y] or (player != 1 && player != 2)
          GameModelError.new("INVALID_MOVE")
        else
          @game_state[x][y]=player
        end
      end
      def marshal
        {game_status: @game_status,game_state: @game_state}
      end
      def self.new_game
        game_state=[]
        3.times {game_state.push([])}
        ttg=TicTacGame.new(game_state,:new)
        return ttg
      end
    end
  end
end
if __FILE__ == $0
  puts "yippee"
end
