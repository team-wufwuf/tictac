require 'spec_helper'
require 'repos/game'

RSpec.describe TicTac::Repos::GameRepo do
  let(:block_adapter) { double(:block_adapter, new:      chain) }
  let(:chain)         { double(:chain,         get_chain: game) }

  let(:player1) { 'joe' }
  let(:player2) { 'theodore' }

  let(:first_turn) {
    {
      rules: {
        game:           'tic_tac_game',
        players: {
          player1 => {player: 1},
          player2 => {player: 2}
        }
      }
    }
  }

  Block = Struct.new(:signer, :data)

  let(:game) {
    [Block.new(player1, first_turn)]
  }

  before do
    described_class.block_adapter = block_adapter
  end

  subject { described_class.new('randomstring') }

  it 'creates a new game' do
    game = subject.game

    expect(game.state).to          eq :pending
    expect(game.current_player).to eq 1
    expect(game.board).to          eq TicTac::Models::EMPTY_BOARD
  end
end
