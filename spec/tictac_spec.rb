require 'spec_helper'
require 'appendlog'

RSpec.describe TicTac::Block do
  subject { described_class.from_data({'hello': 'world'}, nil) }

  it "is signed" do
    expect(subject.signed?).to eq true
  end

  it 'can append another block' do
    next_block = subject.append({"another": "message"})
    expect(next_block.signed?).to eq true

    expect(described_class.new(next_block.prev)).to eq subject
  end

  it 'can get the whole chain' do
    next_block = subject.append({'another': 'message'})

    chain = next_block.get_chain

    expect(chain[0]).to eq subject
    expect(chain[1]).to eq next_block
  end

end

