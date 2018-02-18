require 'spec_helper'

require 'pty'
require 'securerandom'

require 'appendlog'
require 'config'
require 'identity'
require 'repos/game'

describe 'pubsub' do
  let(:tmp_dir)  { ENV['TICTAC_TEST_DIR'] || File.join(__dir__, 'tmp') }
  let(:cfg)      { TicTac::Config.new(tmp_dir) }

  let(:player1) { TicTac::Identity.new('joe',  cfg) }
  let(:player2) { TicTac::Identity.new('jane', cfg) }

  let(:channel) { SecureRandom.hex }

  def publish_first_turn
    first_turn = {
      rules: {
        game: 'tic_tac_game',
        players: {
          player1.public_key_link => {player: 1},
          player2.public_key_link => {player: 2}
        }
      }
    }

    block = TicTac::Block.from_data(player1, nil, first_turn)
    Publisher.publish(block.ipfs_addr)
  end

  def set_game(game)
    @game = game
  end

  def set_block(block)
    @current_block = block
  end

  attr_reader :game, :current_block

  module Publisher
    class << self
      attr_accessor :channel

      def publish(addr)
        %x{ipfs pubsub pub #{channel} #{addr} '\n'}
      end
    end
  end

  before(:each) do
    TicTac::Repos::GameRepo.block_adapter = TicTac::Block
    TicTac::Repos::GameRepo.publisher     = Publisher

    Publisher.channel = channel

    Thread.abort_on_exception = true

    pub_thread = Thread.new do
      PTY.spawn "ipfs pubsub sub #{channel}" do |stdout, stdin, pid|
        stdout.each do |line|
          block, game = TicTac::Repos::GameRepo.read_game(line)
          set_game game
          set_block block
        end
      end
    end

    sleep 0.5
  end

  it 'can actually read data' do
    block = publish_first_turn

    sleep 0.5
    expect(game.state).to eq :pending
  end

  it 'can actually read data' do
    block = publish_first_turn

    sleep 0.5

    TicTac::Repos::GameRepo.add_move_to_game(current_block, player2, {})

    sleep 0.5

    expect(game.state).to eq :accepted
  end
end
