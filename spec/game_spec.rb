require 'spec_helper'
require 'repos/game'

RSpec.describe TicTac::Repos::GameRepo do
  let(:block_adapter) { double(:block_adapter, new: starter_block) }
  let(:starter_block) { Block.new(player1, first_turn).tap { |b| b.get_chain = [b] } }

  let(:player1) { 'joe' }
  let(:player2) { 'theodore' }

  let(:first_turn) {
    {
      rules: {
        game: 'tic_tac_game',
        players: {
          player1 => {player: 1},
          player2 => {player: 2}
        }
      }
    }
  }

  Block = Struct.new(:signer, :data, :get_chain) do
    def append(signer, data)
      Block.new(signer, data).tap do |b|
        b.get_chain = get_chain.concat([b])
      end
    end

    def prev
      get_chain.length > 1 ? get_chain[-1] : nil
    end
  end

  let(:game_blocks) {
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

  # some valid games to player
  context "Player1 straight across the top" do
    let(:turns) do [
      [player1, 0, 0],
      [player2, 2, 2],
      [player1, 0, 1],
      [player2, 2, 1],
      [player1, 0, 2]
    ] end

    let(:expected_state) { :victory }

    it 'runs through the game and produces the expected state' do
      subject.process_move(accept_json(player2))

      turns.each do |turn|
        subject.process_move(turn_json(*turn))
        puts subject.game.pretty_print
      end

      game = subject.game

      expect(game.state).to eq expected_state
    end
  end

  def accept_json(player)
    {player: player}
  end

  def turn_json(player, posx, posy)
    {player: player, x: posx, y: posy}
  end
end
