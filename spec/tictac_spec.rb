require_relative '../tictac'
require_relative '../appendlog'
RSpec.describe TicTac::AppendLog do
  it "puts the lotion in the basket" do
    a=TicTac::AppendLog.new
    expect(TicTac::Block.new(a.new_entry({"hello":"World"})).signed?).to eq true
  end
end

