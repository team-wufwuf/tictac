require 'base64'
require 'open3'
require 'json'
require 'openssl'

require_relative 'config'

module TicTac
  class Identity
    attr_accessor :cfg
    def initialize(keyname,cfg=::TicTac.cfg)
      @cfg = cfg
      setup(keyname)
    end
    def self.import_or_create_privkey_from_keystore(name="self")
      default_ipfs_dir="#{ENV['HOME']}/.ipfs"
      privkey_ipfs_path = "#{ENV['IPFS_PATH'] ? ENV['IPFS_PATH'] : default_ipfs_dir}/keystore/#{name}"
      if !File.exist?(privkey_ipfs_path)
        result=%x(ipfs key gen -t=rsa -s=4096 #{name})
      end
      privkey_ipfs=Base64.strict_encode64(File.read(privkey_ipfs_path))
      private_key=%x(echo #{privkey_ipfs} | ipfs_keys_export)
    end

    def setup(keyname)
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
      if keyname == "self"
        key64=ipfs_config["Identity"]["PrivKey"]
        private_key  = %x(echo #{key64} | ipfs_keys_export)
      else
        private_key = Identity.import_or_create_privkey_from_keystore(keyname)
      end
      File.write(private_path, private_key)
      pkey_obj = OpenSSL::PKey::RSA.new(File.read(cfg.private_path))

      File.write(pub_path, pkey_obj.public_key.export)

      pkey_openssl_ipfsaddr = Open3.popen3("ipfs add -Q") do |i,o,e|
        i.write("#{pubkey_ipfs}\n" + pkey_obj.public_key.export)
        i.close
        o.read
      end.chomp
      File.write(ipfslink_path, pkey_openssl_ipfsaddr)
      File.write(ipfspub_path, pubkey_ipfs)
      puts "IMPORTED\t#{keyname}"
      self
    end
    def private_path
      cfg.tictac_join("#{@keyname}.pem")
    end

    def ipfspub_path
      cfg.tictac_join("#{@keyname}.ipfspub")
    end

    def ipfslink_path
      cfg.tictac_join("#{@keyname}.ipfslink")
    end
    def pub_path
      cfg.tictac_join("#{@keyname}.pub")
    end

    def tictac_dir
      @tictac_dir ||= File.join(cfg.ipfs_path, 'tictac')
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

    class IpfsPathError < StandardError
    end
end
