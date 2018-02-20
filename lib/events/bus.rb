module Events
  class Bus
    def initialize
      @listeners = {}
    end

    def publish(event_name, *args)
      get_listeners(event_name).each do |listener|
        listener.(*args)
      end
    end

    def subscribe(event_name, callable)
      @listeners[event_name] ||= []
      @listeners[event_name].push callable
    end

    private

    def get_listeners(event_name)
      @listeners[event_name] || []
    end 
  end
end
