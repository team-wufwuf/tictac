require 'openssl'
require 'base64'
require 'json'
require_relative 'tictac'
module TicTac
  class AppendLog
    def initialize(initial_state=Empty_log)
      @pkey=OpenSSL::PKey::RSA.new(File.read(Private_key))
      @log=[]
      if initial_state == Empty_log
        obj={last_log: nil, payload: ''}
        @log.push(signed_obj(obj))
      else
        #TODO verification of chain so far
      end
      
    end
    def verify_entry(log_entry)
      
    end
    def new_entry(obj)
      last_payload=JSON.parse(%x(ipfs cat #{@log.last}),symbolize_names: true)
      obj[:last_log]=@log.last
      sobj=signed_obj(obj)
      @log.push(sobj)

    end
    def signed_obj(obj)
      json_obj=JSON.dump(obj)
      signature=Base64.strict_encode64(@pkey.sign(OpenSSL::Digest::SHA256.new,json_obj))
      signed_obj=JSON.dump({payload: Base64.strict_encode64(json_obj),
                  signature: signature,
                  signer: File.read(Public_key)
                 })
      %x(ipfs add -Q <<<  '#{signed_obj}').chomp
    end
  end
end
a=TicTac::AppendLog.new
print a.new_entry({"hello":"World"})
  
