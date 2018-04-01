require 'spec_helper'

require 'pty'
require 'securerandom'
require 'ipfs/pubsub'
require 'ipfs/block'
require 'ipfs/config'
require 'ipfs/identity'
require 'repos/game'

describe 'pubsub' do
  let(:tmp_dir)  { ENV['TICTAC_TEST_DIR'] || File.join(__dir__, 'tmp') }
  let(:cfg)      { Ipfs::Config.new(tmp_dir) }

  let(:player1) { Ipfs::Identity.new('joe',  cfg) }
  let(:player2) { Ipfs::Identity.new('jane', cfg) }

  let!(:channel) { SecureRandom.hex }
  let!(:publisher) { Ipfs::Publisher.new(channel) }
  let!(:listener) { Ipfs::Listener.new(channel) }
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

  attr_accessor :current_block, :game

  before(:each) do
    TicTac::Repos::GameRepo.block_adapter = Ipfs::Block
    TicTac::Repos::GameRepo.publisher     = publisher
    Thread.abort_on_exception = true
    Thread.new do
      listener.listen do |event|
        block, game = TicTac::Repos::GameRepo.read_game(event)
        self.game = game
        self.current_block = block
      end
    end
  end

  it 'can actually read data' do
    block = Ipfs::Block.from_data(player1, nil, first_turn)
    publisher.publish(block.ipfs_addr)
    sleep 2.0
    expect(game.state).to eq :pending
  end

  it 'can actually read data' do
    block = Ipfs::Block.from_data(player1, nil, first_turn)
    publisher.publish(block.ipfs_addr)
    sleep 5.0
    TicTac::Repos::GameRepo.add_move_to_game(current_block, player2, {})
    sleep 5.0
    expect(game.state).to eq :accepted
  end
end
