module TicTac
  module Models
    # board state nxn array of integers. 0 neutral. 1 crosses. -1 circles.
    # board status 'pending' 'in_play' 'crosses' (win) 'circles' (win) 'draw'
    class TicTacGame
      attr_accessor :game_status
      def self.name
        "tic-tac-toe"
      end
      def self.new_game 
        game_state=[]
        3.times {game_state.push([])}
        game_status=:new
        {game_status: game_status,game_state: game_state}
      end
    end
  end
end
if __FILE__ == $0
  puts "yippee"
end
