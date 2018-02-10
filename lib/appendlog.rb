require 'optparse'
require 'open3'
require 'openssl'
require 'base64'
require 'json'
require_relative 'config'
require_relative 'identity'

module TicTac
  class SSLError < StandardError
  end

  class Block
    #this class is immutable.
    attr_accessor :signature, :signer, :prev, :ipfs_addr, :data
    def initialize(ipfs_addr)
      @ipfs_addr=ipfs_addr
      @block=JSON.parse(%x(ipfs cat #{ipfs_addr}),symbolize_names: true)
      @signature=Base64.decode64(@block[:signature])
      @payload=JSON.parse(Base64.decode64(@block[:payload]),symbolize_names: true)
      @data=@payload[:data]
      @signer=@payload[:signer]
      @prev=@payload[:prev]
    end

    def append(identity,data)
      TicTac::Block.from_data(identity,@ipfs_addr,data)
    end

    def get_chain
      block=self
      chain=[]
      while block.prev != nil
        if !block.signed?
          raise SSLError.new("BAD SIGNATURE")
          return chain
        end
        chain.push(block)
        block=TicTac::Block.new(block.prev)        
      end
      chain.push(block)
      chain.reverse #so it's from oldest to newest.
    end

    def self.from_data(id,last_block,data)
      payload = {
        data: data,
        signer: id.public_key_link,
        prev: last_block
      }
      json_payload = JSON.dump(payload)
      signature = Base64.strict_encode64(id.private_key.sign(OpenSSL::Digest::SHA256.new,json_payload))

      block={
        signature: signature,
        payload: Base64.strict_encode64(json_payload)
      }

      new_block_addr=Open3.popen3("ipfs add -Q") do |i,o,e|
        i.write(JSON.dump(block));i.close;o.read
      end.chomp
      
      new(new_block_addr)
    end

    def signed?
      pubkey=TicTac::Identity.resolve_public_key_link(@signer)[:public_key]
      digest_algo=OpenSSL::Digest::SHA256.new
      pubkey.verify(digest_algo,@signature, JSON.dump(@payload))
    end

    def ==(block)
      block.data == data && block.signer == signer && block.prev == prev
    end
  end
end

if __FILE__ == $0
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
    chain=TicTac::Block.new(o[:chain]).get_chain
    chain.each do |b| puts b.data end
  end
  if o[:init]
    puts game
    exit 0
  end
  if o[:chain] && o[:data]
    id=TicTac::Identity.new
    chain=TicTac::Block.new(o[:chain]).get_chain
    chain.last.append(id,data).ipfs_addr
  end
end


