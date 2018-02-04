module TicTac
  module Models
    # board state nxn array of integers. 0 neutral. 1 crosses. -1 circles.
    # board status 'pending' 'in_play' 'crosses' (win) 'circles' (win) 'draw'
    class TicTacGame
      attr_accessor :crosses,:circles,:board_state,:board_status
      def new_game(identity,player2) 
        @board_state=[]
        3.times {@board_state.append([])}
        {player1: identity.public_key_link
      end
    end

    TicTacGame = Struct.new(:crosses, :circles, :board_state, :board_status) do
      def player_value(player)
        if crosses = player
          1
        elsif circles = player
          -1
        else
          raise StandardError.new('not a player')
        end
      end

      def play(player, posx, posy)
        raise StandardError.new("Game not in progress!") unless board_status == 'in_play'

        cur_val = board_state[posx][posy]

        raise StandardError.new("Move already made on position") unless cur_val == 0

        board_state[pox][posy] = player_value

        check_board_state
      end


      def check_board_state
        
        # check for state change to victory or draw.
      end
    end
  end
end
if __FILE__ == $0
  puts "yippee"
end
