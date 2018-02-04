module TicTac
  module Models
    class GameModelError < StandardError
    end
    # board state nxn array of integers. 0 neutral. 1 crosses. -1 circles.
    # board status 'pending' 'in_play' 'crosses' (win) 'circles' (win) 'draw'
    attr_accessor :game_status, :game_state
    class TicTacGame
      def self.assert_valid_new_game(game_status,game_state)
        if !game_status == "NEW" ||
           !game_state.class == Array ||
           !game_state.length == 3 ||
           !game_state.all? {|r| r.length == 3 } ||
           !game_state.all? {|r| r.all? { |x| x == 1 or x == 0 or x == nil } }
          raise GameModelError.new("INVALID_NEW_GAME")
        end
      end
      def initialize(game_status,game_state)
        TicTacGame.assert_valid_new_game(game_status,game_state)
        @game_status,@game_state=game_status,game_state
      end
      def self.name
        "tic-tac-toe"
      end
      def pretty_print
        mapping={0 => "x",1 => "o",nil => " "}
        x=@game_state.collect {|r| r.collect { |x| mapping[x] } }
        
        """
         _____
        |#{x[0][0]}|#{x[1][0]}|#{x[2][0]}|
        |#{x[0][1]}|#{x[1][1]}|#{x[2][1]}|
        |#{x[0][2]}|#{x[1][2]}|#{x[2][2]}|
        -------
        """
      end
      def move(player,move)
        x,y=move[:x],move[:y]
        if x > 2 or y > 2 or @game_state[x][y] or (player != 1 && player != 2)
          GameModelError.new("INVALID_MOVE")
        else
          @game_state[x][y]=player
        end
      end
      def game_status
        @game_status
      end
      def game_state
        @game_state
      end
      def self.new_game
        game_state=[]
        3.times {|| game_state.push([nil,nil,nil]) }
        ttg=TicTacGame.new("NEW",game_state)
        return ttg
      end
    end
    end
  end
if __FILE__ == $0
  puts "yippee"
end
