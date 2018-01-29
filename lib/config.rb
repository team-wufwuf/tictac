require 'fileutils'
require 'openssl'

module TicTac
  IPFS_PATH=ENV['IPFS_PATH'] ? ENV['IPFS_PATH'] : File.absolute_path("#{ENV['HOME']}/.ipfs")

  class Config 
    def initialize(ipfs_path)
      @ipfs_path = ipfs_path
    end

    attr_reader :ipfs_path

    def tictac_dir
      @tictac_dir ||= File.join(ipfs_path, 'tictac')
    end

    def public_key
      @public_key ||= File.read(File.join(tictac_dir, 'self.ipfspub'))
    end

    def public_key_link
      @public_key_link ||= File.read(File.join(tictac_dir, 'self.ipfslink'))
    end

    def private_key
      @private_key ||= OpenSSL::PKey::RSA.new(File.read(File.join(tictac_dir, 'self.pem')))
    end

    def empty_log
      "QmW2iRGLDBBTa4Rorfoj3rZ6bUfSfXRtPeJavjSUKs5CKN"
    end
  end

  def self.cfg
    Config.new(ENV['IPFS_PATH'] || File.absolute_path(File.join(ENV['HOME'], '.ipfs')))
  end
end
