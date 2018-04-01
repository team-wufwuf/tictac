require 'pty'
require 'timeout'
require 'json'
module Ipfs
  # publish a block to a channel on the local IPFS pubsub mechanism.
  class Publisher
    def initialize(channel)
      @channel = channel
    end

    def publish(message)
      message_str = JSON.dump(message)
      `ipfs pubsub pub #{@channel} '#{message_str}' '\n'`
    end
  end

  # Fire up a thread that subscribes to an IPFS pubsub channel
  # and deliver its events to a queue
  class Listener
    def initialize(channel)
      @events = Queue.new
      Thread.new do
        PTY.spawn "ipfs pubsub sub #{channel}" do |stdout, _stdin, _pid|
          stdout.each do |line|
            @events.push(JSON.parse(line))
          end
        end
      end
    end

    def listen
      # to stop the listener, have your block return false.
      while (e = @events.pop)
        yield(e) || break
      end
    end

    def pop
      @events.pop
    end

    def pop_nb
      @events.pop unless @events.empty?
    end
  end
end
