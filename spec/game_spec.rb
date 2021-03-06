require 'spec_helper'
require 'repos/game'

RSpec.describe TicTac::Repos::GameRepo do
  let(:block_adapter) { double(:block_adapter, new: starter_block) }
  let(:starter_block) do
    Block.new(player1.public_key_link, first_turn).tap { |b| b.get_chain = [b] }
  end

  let(:player1) { double(:player1, public_key_link: 'joe') }
  let(:player2) { double(:player2, public_key_link: 'theodore') }

  let(:publisher) { spy(:publisher) }

  let(:first_turn) do
    {
      rules: {
        game: 'tic_tac_game',
        players: {
          player1.public_key_link.to_sym => { player: 1 },
          player2.public_key_link.to_sym => { player: 2 }
        }
      }
    }
  end

  Block = Struct.new(:signer, :data, :get_chain) do
    def append(signer, data)
      Block.new(signer.public_key_link, data).tap do |b|
        b.get_chain = get_chain.concat([b])
      end
    end

    def ipfs_addr
      nil
    end

    def prev
      get_chain.length > 1 ? get_chain[-1] : nil
    end
  end

  let(:game_blocks) do
    [Block.new(player1.public_key_link, first_turn)]
  end

  before do
    described_class.block_adapter = block_adapter
    described_class.publisher     = publisher
  end

  subject { described_class }

  it 'creates a new game' do
    _, game = subject.read_game('soemthing')

    expect(game.state).to          eq :pending
    expect(game.current_player).to eq 1
    expect(game.board).to          eq TicTac::Models::EMPTY_BOARD
  end

  # some valid games to player
  context 'Player1 straight across the top' do
    let(:turns) do
      [
        [player1, 0, 0],
        [player2, 2, 2],
        [player1, 0, 1],
        [player2, 2, 1],
        [player1, 0, 2]
      ]
    end

    let(:expected_state) { :victory }

    it 'runs through the game and produces the expected state' do
      game_asserter(turns, expected_state)
    end
  end

  context 'Draw game' do
    let(:turns) do
      [
        [player1, 0, 0],
        [player2, 2, 2],
        [player1, 0, 1],
        [player2, 2, 1],
        [player1, 2, 0],
        [player2, 0, 2],
        [player1, 1, 1],
        [player2, 1, 0],
        [player1, 1, 2]
      ]
    end

    let(:expected_state) { :draw }

    it 'runs through the game and produces the expected state' do
      game_asserter(turns, expected_state)
    end
  end

  def game_asserter(turns, expected_state)
    block, = subject.read_game('something')
    block, game = subject.add_move_to_game(block, player2, accept_json(player2))
    _, game = play_prepared_game(block, game, turns)

    expect(game.state).to eq expected_state
  end

  def play_prepared_game(block, game, turns)
    turns.each do |turn|
      block, game = subject.add_move_to_game(block, turn[0], turn_json(*turn))
      puts game.pretty_print
    end
    [block, game]
  end

  def accept_json(player)
    { player: player.public_key_link }
  end

  def turn_json(_player, posx, posy)
    { x: posx, y: posy }
  end
end
