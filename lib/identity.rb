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

    def setup
      validate

      if !File.directory?(cfg.tictac_dir)
        puts "CREATE\tTICTAC_DIR\t\t#{cfg.tictac_dir}"
        FileUtils.mkdir_p(cfg.tictac_dir)
      else
        puts "EXISTS\t\TICTAC_DIR\t\t#{cfg.tictac_dir}"
      end

      config_file = File.read(File.join(cfg.ipfs_path, 'config'))
      ipfs_config = JSON.load(config_file)

      privkey_ipfs = ipfs_config["Identity"]["PrivKey"]
      pubkey_ipfs  = ipfs_config["Identity"]["PeerID"]

      private_key = %x(echo #{privkey_ipfs} | ipfs_keys_export)
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
      puts "IMPORTED\tself"
    end

    def tictac_join(args)
      File.join(cfg.tictac_dir, *args)
    end

    def ipfspub_path
      tictac_join('self.ipfspub')
    end

    def ipfslink_path
      tictac_join('pubkey.ipfslink')
    end

    def pub_path
      tictac_join('self.pub')
    end

    def private_path
      tictac_join('self.pem')
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
