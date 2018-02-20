require 'spec_helper'
require 'events/bus'

RSpec.describe Events::Bus do
  class SomePublisher
    attr_accessor :bus

    def run(message)
      bus.publish(:foo_event, message)
    end
  end

  subject { described_class.new }

  let(:publisher) { SomePublisher.new.tap { |s| s.bus = subject } }

  it 'publishes messages to subscribers' do
    message = 'UNCHANGED'
    message2 = 'UNCHANGED'

    p = Proc.new { |msg| message = msg }
    p2 = Proc.new { |msg| message2 = msg }

    subject.subscribe(:foo_event, p)
    subject.subscribe(:foo_event, p2)

    publisher.run('IMPORTANT_DATA')

    expect(message).to eq 'IMPORTANT_DATA'
    expect(message2).to eq 'IMPORTANT_DATA'
  end

  it 'doesnt care if there are not subscribers' do
    publisher.run('IMPORTANT_DATA')
  end
end
