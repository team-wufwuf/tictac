# coding: utf-8
require 'fileutils'
require 'openssl'

module TicTac
  IPFS_PATH=ENV['IPFS_PATH'] ? ENV['IPFS_PATH'] : File.absolute_path("#{ENV['HOME']}/.ipfs")

  class Config
    def setup
      private_key = Identity.import_or_create_privkey_from_keystore("self")
    end
    attr_reader :ipfs_path
    def ipfspub_path
      tictac_join("#{@keyname}.ipfspub")
    end

    def ipfslink_path
      tictac_join("#{@keyname}.ipfslink")
    end
    def tictac_dir
      return "#{ipfs_path}/tictac"
    end
    def pub_path
      tictac_join("#{@keyname}.pub")
    end
    def ipfs_path
      default_ipfs_dir="#{ENV['HOME']}/.ipfs"
      "#{ENV['IPFS_PATH'] ? ENV['IPFS_PATH'] : default_ipfs_dir}"
    end
    def tictac_join(args)
      File.join(tictac_dir, *args)
    end
    def private_path
      tictac_join("#{@keyname}.pem")
    end
  end
  def self.cfg
    Config.new
  end

end

