require 'open3'
require 'openssl'
require 'base64'
require 'json'

require_relative 'identity'

module Ipfs
  class SSLError < StandardError
  end

  # immutable block representation
  class Block
    MAX_CHAIN_LENGTH = 100_000 # just a thought

    attr_accessor :signature, :ipfs_addr

    def initialize(ipfs_addr)
      @ipfs_addr = ipfs_addr
      @block     = JSON.parse(
        `ipfs cat #{ipfs_addr.chomp}`,
        symbolize_names: true
      )
      @signature = Base64.decode64(@block[:signature])

      @payload = JSON.parse(
        Base64.decode64(@block[:payload]), symbolize_names: true
      )
    end

    def data
      @payload[:data]
    end

    def signer
      @payload[:signer]
    end

    def prev
      @payload[:prev]
    end

    def append(identity, data)
      self.class.from_data(identity, @ipfs_addr, data)
    end

    def get_chain(max_length: MAX_CHAIN_LENGTH)
      block = self

      chain     = [block]
      addresses = {}

      # follow the "blockchain" backwards appending each block to the chain.
      Kernel.loop do
        validate_chain(chain, addresses, max_length)

        break if block.prev.nil?

        block, chain, addresses = add_block_to_chain(block, chain, addresses)
      end

      chain.reverse # so it's from oldest to newest.
    end

    def add_block_to_chain(block, chain, addresses)
      prev_block = self.class.new(block.prev)

      addresses[block.ipfs_addr] = true

      chain.push(prev_block)

      [prev_block, chain, addresses]
    end

    def validate_chain(chain, addresses, max_length)
      # require signed blocks
      raise(SSLError, 'BAD SIGNATURE') unless chain.last.signed?

      # reasonable performance considerations
      if max_length != -1 && chain.length > max_length
        raise ChainError, 'CHAIN TOO LONG'
      end

      # cyclical blockchain causes an infinite loop.
      last_addr = chain.last.ipfs_addr
      raise(ChainError, 'CYCLICAL BLOCKCHAIN') if addresses.key? last_addr
    end

    def self.from_data(id, last_block, data)
      signer = id.public_key_link

      block = payload_to_block(id, data: data, signer: signer, prev: last_block)

      new_block_addr = Open3.popen3('ipfs add -Q') do |i, o, _e|
        i.write(JSON.dump(block))
        i.close
        o.read
      end.chomp

      new(new_block_addr)
    end

    def self.payload_to_block(id, payload)
      json_payload = JSON.dump(payload)

      signature    = Base64.strict_encode64(
        id.private_key.sign(OpenSSL::Digest::SHA256.new, json_payload)
      )

      {
        signature: signature,
        payload: Base64.strict_encode64(json_payload)
      }
    end

    def signed?
      pubkey      = Ipfs::Identity.resolve_public_key_link(signer)[:public_key]
      digest_algo = OpenSSL::Digest::SHA256.new

      pubkey.verify(
        digest_algo,
        @signature,
        JSON.dump(@payload)
      )
    end

    def ==(other)
      other.data == data && other.signer == signer && other.prev == prev
    end

    class ChainError < StandardError
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'optparse'
  require_relative '../identity'

  o = { keyname: 'self', data: nil, chain: nil }
  parser = OptionParser.new do |opts|
    opts.banner = 'Usage: appendlog.rb -n keyname -d data -c chain'
    opts.on('-n', '--keyname name', 'Name') { |x| o[:name] = x }
    opts.on('-d', '--data data', 'Data') { |x| o[:data] = x }
    opts.on('-c', '--chain chain', 'Chain') { |x| o[:chain] = x }
    opts.on('-p', '--print-data') { |x| o[:print_data] = x }
    opts.on('-i', '--init') { |x| o[:init] = x }
    opts.on('-o', '--opponent opponent') { |x| o[:opponent] = x }
  end

  parser.parse!

  # true if init is incompatible with print_data and chain
  incompatible_with_print = (o[:init] && (o[:print_data] || o[:chain]))

  # true if init requires opponent (as an ipfs pubkey link)
  requires_opponent = (o[:init] && !o[:opponent])

  if incompatible_with_print || requires_opponent
    puts 'no good'
    exit(1)
  end

  if o[:print_data]
    chain = Ipfs::Block.new(o[:chain]).get_chain
    chain.each do |b|
      puts b.data
    end
  end

  if o[:init]
    puts game
    exit 0
  end

  if o[:chain] && o[:data]
    id = Ipfs::Identity.new
    chain = Ipfs::Block.new(o[:chain]).get_chain
    chain.last.append(id, data).ipfs_addr
  end
end
