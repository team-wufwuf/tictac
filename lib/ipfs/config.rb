require 'fileutils'
require 'openssl'

# IPFS adapter
module Ipfs
  IPFS_PATH = ENV['IPFS_PATH'] || File.absolute_path("#{ENV['HOME']}/.ipfs")

  # IPFS application configuration
  class Config
    def initialize(ipfs_path = IPFS_PATH)
      @ipfs_path = ipfs_path
      `ipfs -c #{@ipfs_path} init` unless File.exist?("#{@ipfs_path}/config")
    end

    def setup
      Identity.import_or_create_privkey_from_keystore('self')
    end

    attr_reader :ipfs_path

    def ipfspub_path
      tictac_join("#{@keyname}.ipfspub")
    end

    def ipfslink_path
      tictac_join("#{@keyname}.ipfslink")
    end

    def tictac_dir
      "#{ipfs_path}/tictac"
    end

    def pub_path
      tictac_join("#{@keyname}.pub")
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
