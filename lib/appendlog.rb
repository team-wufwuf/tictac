require 'open3'
require 'openssl'
require 'base64'
require 'json'
require_relative 'config'

module TicTac
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

    def append(data)
      TicTac::Block.from_data(data,@ipfs_addr)
    end

    def get_chain
      block=self
      chain=[]
      while block.prev != nil
        if !block.signed?
          puts "ERROR\tBAD_SIG #{block.ipfs_addr}"
          return chain
        end
        chain.push(block)
        block=TicTac::Block.new(block.prev)        
      end
      chain.push(block)
      chain.reverse #so it's from oldest to newest.
    end

    def self.from_data(data, last_block, private_key: TicTac.cfg.private_key)
      payload = {
        data: data,
        signer: private_key.public_key.export,
        prev: last_block
      }
      json_payload = JSON.dump(payload)
      signature = Base64.strict_encode64(private_key.sign(OpenSSL::Digest::SHA256.new,json_payload))

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
      key=OpenSSL::PKey::RSA.new(@signer)
      digest_algo=OpenSSL::Digest::SHA256.new
      key.verify(digest_algo,@signature, JSON.dump(@payload))
    end

    private

    def ==(block)
      block.data == data && block.signer == signer && block.prev == prev
    end
  end
end

if __FILE__ == $0
  Just_print_data=(ARGV[0] == '--print-data')
  Init=(ARGV[0] == '--init') #create a new game with opponent specified by ARGV[1]
  data=ARGV[0] unless Init
  game=ARGV[1]
  if Init
    game=TicTac::Block.from_data({game:"tic-tac-toe",
                                  player1: TicTac::Ipfs_public_key,
                                  player2: ARGV[1] #ben
                                 },nil).ipfs_addr
  end
  game_chain=TicTac::Block.new(game).get_chain
  if Just_print_data
    game_chain.each do |block|
      puts block.data
    end
  else
    puts game_chain.last.append(data).ipfs_addr
  end
end


  
