module Events
  class Bus
    def initialize
      @listeners = {}
      @listener_id = 0
    end

    def publish(event_name, *args)
      get_listeners(event_name).each do |id, listener|
        listener.(*args)
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

  module Subscriber
    attr_accessor :bus

    def register_events
      @listeners ||= self.class.events.map do |event|
        event_name, callable = event
        Listener.new(
          event_name,
          method(callable),
          bus.subscribe(event_name, method(callable))
        )
      end
    end

    def deregister_events
      get_listeners.each do |listener|
        bus.remove(listener.event_name, listener.id)
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

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

    def get_listeners
      @listeners || []
    end
  end
end
