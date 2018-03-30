module Events
  # event bus to manage events between objects
  class Bus
    def initialize
      @listeners = {}
      @listener_id = 0
    end

    attr_reader :listeners

    def publish(event_name, *args)
      get_listeners(event_name).each do |_id, listener|
        listener.call(*args)
      end
    end

    def remove(listener)
      @listeners[listener.event_name].delete listener.id
    end

    def subscribe(event_name, callable)
      @listener_id += 1
      @listeners[event_name] ||= {}
      @listeners[event_name][@listener_id] = callable
      @listener_id
    end

    private

    def get_listeners(event_name)
      @listeners[event_name] || {}
    end
  end

  Listener = Struct.new(:event_name, :callable, :id)

  # includables
  module Publisher
    attr_accessor :bus

    def publish(event_name, *args)
      bus.publish(event_name, *args) unless bus.nil?
    end
  end

  # turn a class into an event subscriber
  module Subscriber
    attr_accessor :bus

    def register_events
      @listeners = self.class.events.map do |event|
        event_name, callable = event
        Listener.new(
          event_name,
          method(callable),
          bus.subscribe(event_name, method(callable))
        )
      end
    end

    def deregister_events
      listeners.each do |listener|
        bus.remove(listener.event_name, listener.id)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    # class methods
    module ClassMethods
      def events
        @events || []
      end

      def on_event(event_name, &block)
        @events ||= []
        method_name = "on_event_#{block.object_id}".to_sym
        define_method(method_name, &block)
        @events << [event_name, method_name]
      end
    end

    private

    def listeners
      @listeners || []
    end
  end
end
