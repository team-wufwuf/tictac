require 'spec_helper'

require 'pty'
require 'securerandom'

require 'ipfs/block'
require 'ipfs/config'
require 'ipfs/identity'
require 'repos/game'

describe 'pubsub' do
  let(:tmp_dir)  { ENV['TICTAC_TEST_DIR'] || File.join(__dir__, 'tmp') }
  let(:cfg)      { Ipfs::Config.new(tmp_dir) }

  let(:player1) { Ipfs::Identity.new('joe',  cfg) }
  let(:player2) { Ipfs::Identity.new('jane', cfg) }

  let(:channel) { SecureRandom.hex }

  let(:first_turn) do
    {
      rules: {
        game: 'tic_tac_game',
        players: {
          player1.public_key_link => { player: 1 },
          player2.public_key_link => { player: 2 }
        }
      }
    }
  end

  def publish_first_turn
    block = Ipfs::Block.from_data(player1, nil, first_turn)
    Publisher.publish(block.ipfs_addr)
  end

  attr_accessor :current_block, :game

  module Publisher
    class << self
      attr_accessor :channel

      def publish(addr)
        `ipfs pubsub pub #{channel} #{addr} '\n'`
      end
    end
  end

  before(:each) do
    TicTac::Repos::GameRepo.block_adapter = Ipfs::Block
    TicTac::Repos::GameRepo.publisher     = Publisher

    Publisher.channel = channel

    Thread.abort_on_exception = true

    Thread.new do
      PTY.spawn "ipfs pubsub sub #{channel}" do |stdout, _stdin, _pid|
        stdout.each do |line|
          block, game = TicTac::Repos::GameRepo.read_game(line)
          self.game = game
          self.current_block = block
        end
      end
    end

    sleep 0.5
  end

  it 'can actually read data' do
    publish_first_turn

    sleep 0.5
    expect(game.state).to eq :pending
  end

  it 'can actually read data' do
    publish_first_turn

    sleep 0.5

    TicTac::Repos::GameRepo.add_move_to_game(current_block, player2, {})

    sleep 0.5

    expect(game.state).to eq :accepted
  end
end
