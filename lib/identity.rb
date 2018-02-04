require 'base64'
require 'open3'
require 'json'
require 'openssl'

require_relative 'config'

module TicTac

  class Identity
    attr_reader :cfg

    def initialize(cfg=TicTac.cfg)
      @cfg = cfg
    end

    def setup(keyname)
      validate
      @keyname=keyname
      if !File.directory?(cfg.tictac_dir)
        puts "CREATE\tTICTAC_DIR\t\t#{cfg.tictac_dir}"
        FileUtils.mkdir_p(cfg.tictac_dir)
      else
        puts "EXISTS\t\TICTAC_DIR\t\t#{cfg.tictac_dir}"
      end

      config_file = File.read(File.join(cfg.ipfs_path, 'config'))
      ipfs_config = JSON.load(config_file)
      pubkey_ipfs  = ipfs_config["Identity"]["PeerID"]

      private_key = import_or_create_privkey_from_keystore(keyname)
      File.write(private_path, private_key)

      pkey_obj = OpenSSL::PKey::RSA.new(File.read(private_path))

      File.write(pub_path, pkey_obj.public_key.export)

      pkey_openssl_ipfsaddr = Open3.popen3("ipfs add -Q") do |i,o,e|
        i.write("#{pubkey_ipfs}\n" + pkey_obj.public_key.export)
        i.close
        o.read
      end.chomp

      File.write(ipfslink_path, pkey_openssl_ipfsaddr)
      File.write(ipfspub_path, pubkey_ipfs)
      puts "IMPORTED\t#{keyname}"
    end

    def import_or_create_privkey_from_keystore(name="self")
      default_ipfs_dir="#{ENV['HOME']}/.ipfs"
      privkey_ipfs_path = "#{ENV['IPFS_PATH'] ? ENV['IPFS_PATH'] : default_ipfs_dir}/keystore/#{name}"
      if !File.exist?(privkey_ipfs_path)
        result=%x(ipfs key gen -t=rsa -s=4096 #{name})
      end
      privkey_ipfs=Base64.strict_encode64(File.read(privkey_ipfs_path))
      private_key=%x(echo #{privkey_ipfs} | ipfs_keys_export)
    end
    def tictac_join(args)
      File.join(cfg.tictac_dir, *args)
    end

    def ipfspub_path
      tictac_join("#{@keyname}.ipfspub")
    end

    def ipfslink_path
      tictac_join("#{@keyname}.ipfslink")
    end

    def pub_path
      tictac_join("#{@keyname}.pub")
    end

    def private_path
      tictac_join("#{@keyname}.pem")
    end

    def validate
      if !File.directory?(cfg.ipfs_path)
        raise IpfsPathError.new("ERROR\tPATH_DNE\t\t#{cfg.ipfs_path}")
      end

      [ipfspub_path, ipfslink_path, pub_path, private_path].each do |path|
        if File.exists?(path)
          raise IpfsPathError.new("ERROR\tFILE_EXISTS\t\t#{path}")
        end
      end
    end

    class IpfsPathError < StandardError
    end

  end
end
