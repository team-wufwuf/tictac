require 'open3'
require 'openssl'
require 'base64'
require 'json'

require_relative 'identity'

module Ipfs
  class SSLError < StandardError
  end

  class Block
    MAX_CHAIN_LENGTH = 100000 # just a thought

    #this class is immutable.
    attr_accessor :signature, :signer, :prev, :ipfs_addr, :data

    def initialize(ipfs_addr)
      @ipfs_addr = ipfs_addr
      @block     = JSON.parse(%x(ipfs cat #{ipfs_addr.chomp}), symbolize_names: true)
      @signature = Base64.decode64(@block[:signature])

      @payload = JSON.parse(Base64.decode64(@block[:payload]), symbolize_names: true).tap do |p|
        @data   = p[:data]
        @signer = p[:signer]
        @prev   = p[:prev]
      end
    end

    def append(identity, data)
      self.class.from_data(identity, @ipfs_addr, data)
    end

    def get_chain(max_length: MAX_CHAIN_LENGTH)
      block = self

      chain     = []
      addresses = {}

      # follow the "blockchain" backwards appending each block to the chain.
      while true
        # require signed blocks
        raise SSLError.new("BAD SIGNATURE") unless block.signed?

        # reasonable performance considerations
        raise ChainError.new("CHAIN TOO LONG") if max_length != -1 && chain.length > max_length

        # cyclical blockchain causes an infinite loop.
        raise ChainError.new("CYCLICAL BLOCKCHAIN") if addresses.has_key? block.ipfs_addr

        addresses[block.ipfs_addr] = true

        chain.push(block)

        break if block.prev.nil?

        block = self.class.new(block.prev)        
      end

      chain.reverse # so it's from oldest to newest.
    end

    def self.from_data(id, last_block, data)
      payload = {
        data:   data,
        signer: id.public_key_link,
        prev:   last_block
      }

      json_payload = JSON.dump(payload)
      signature    = Base64.strict_encode64(id.private_key.sign(OpenSSL::Digest::SHA256.new,json_payload))

      block = {
        signature: signature,
        payload: Base64.strict_encode64(json_payload)
      }

      new_block_addr = Open3.popen3("ipfs add -Q") do |i,o,e|
        i.write(JSON.dump(block));i.close;o.read
      end.chomp
      
      new(new_block_addr)
    end

    def signed?
      pubkey      = Ipfs::Identity.resolve_public_key_link(@signer)[:public_key]
      digest_algo = OpenSSL::Digest::SHA256.new

      pubkey.verify(
        digest_algo,
        @signature,
        JSON.dump(@payload)
      )
    end

    def ==(block)
      block.data == data && block.signer == signer && block.prev == prev
    end

    class ChainError < StandardError
    end
  end
end

if __FILE__ == $0
  require 'optparse'
  require_relative '../identity'

  o={keyname: "self",data: nil, chain: nil}
  parser=OptionParser.new do |opts|
    opts.banner = "Usage: appendlog.rb -n keyname -d data -c chain"
    opts.on('-n', '--keyname name', 'Name')  {|x| o[:name] = x }
    opts.on('-d', '--data data', 'Data') { |x| o[:data] = x }
    opts.on('-c', '--chain chain', 'Chain') { |x| o[:chain] = x }
    opts.on('-p','--print-data') {|x| o[:print_data]=x }
    opts.on('-i','--init') {|x| o[:init]=x }
    opts.on('-o','--opponent opponent') {|x| o[:opponent]=x }
  end
  parser.parse!
  if ((o[:init] && ( o[:print_data] || o[:chain] )) || #init is incompatible with print_data and chain
      (o[:init] && !o[:opponent]))                #init requires opponent (as an ipfs pubkey link)
    puts "no good"
    exit(1)
  end
  if o[:print_data]
    chain=Ipfs::Block.new(o[:chain]).get_chain
    chain.each do |b| puts b.data end
  end
  if o[:init]
    puts game
    exit 0
  end
  if o[:chain] && o[:data]
    id=Ipfs::Identity.new
    chain=Ipfs::Block.new(o[:chain]).get_chain
    chain.last.append(id,data).ipfs_addr
  end
end


