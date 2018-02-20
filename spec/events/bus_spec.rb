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

  class InclusionSubscriber
    include Events::Subscriber

    attr_reader :message

    on_event(:foo_test) do |msg|
      @message = msg
    end
  end

  class InclusionPublisher
    include Events::Publisher

    def run
      publish(:foo_test, 'TRANSMISSION_SUBMIT')
    end
  end

  context 'using inclusion' do
    let(:publisher)  { InclusionPublisher.new.tap { |p| p.bus = subject } }
    let(:subscriber) { InclusionSubscriber.new.tap { |s| s.bus = subject ; s.register_events } }

    it 'publishes and subscribes' do
      subscriber
      publisher.run
      expect(subscriber.message).to eq 'TRANSMISSION_SUBMIT'
    end
  end
end
