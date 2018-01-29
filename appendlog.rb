require 'open3'
require 'openssl'
require 'base64'
require 'json'
require_relative 'tictac'
module TicTac
  class Block
    #this class is immutable.
    attr_accessor :signature,:signer,:prev,:ipfs_addr,:data
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
        chain.push(block.prev)
        block=TicTac::Block.new(block.prev)        
      end
      chain.push(block.ipfs_addr)
      chain
    end
    def self.from_data(data,last_block)
      payload={ data: data,
                 signer: Private_key.public_key.export,
                 prev: last_block
              }
      json_payload=JSON.dump(payload)
      signature=Base64.strict_encode64(Private_key.sign(OpenSSL::Digest::SHA256.new,json_payload))
      block={
        signature: signature,
        payload: Base64.strict_encode64(json_payload)
      }
      new_block_addr=Open3.popen3("ipfs add -Q") do |i,o,e|
        i.write(JSON.dump(block));i.close;o.read
      end.chomp
      TicTac::Block.new(new_block_addr)
    end
    def signed?
      key=OpenSSL::PKey::RSA.new(@signer)
      digest_algo=OpenSSL::Digest::SHA256.new
      key.verify(digest_algo,@signature, JSON.dump(@payload))
    end
  end
end
    
new_game_request=TicTac::Block.from_data({game:"tic-tac-toe",
                                            player1: TicTac::Ipfs_public_key,
                                            player2: 'QmNMvSwDfroSeS7ob2WfU9hd8QKKAK3FFCXernWj9oWuk9' #ben
                                         },nil)
turn1=new_game_request.append({action: "forfeit"})
turn2=turn1.append({action: "seriously"})

print TicTac::Block.new(turn2.ipfs_addr).get_chain

  
