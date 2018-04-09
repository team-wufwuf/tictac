require 'base64'
require 'open3'
require 'json'
require 'openssl'

require_relative 'config'

module Ipfs
  # ipfs identity content
  class Identity
    attr_accessor :cfg

    def self.resolve_public_key_link(ipfs_link)
      authority_link = nil
      pubkey_object = `ipfs cat  #{ipfs_link}`
      obj_lines = pubkey_object.split("\n")
      if obj_lines.first =~ /ipns/
        # optional, and really more of a hint: where we can expect
        #  updates from pubkey's owner to show up.
        authority_link = obj_lines.shift
      end
      pubkey = obj_lines.join("\n")
      key = OpenSSL::PKey::RSA.new(pubkey)
      { public_key: key ? key : nil, authority_link: authority_link }
    end

    def initialize(keyname = 'self', cfg = ::Ipfs.cfg)
      @cfg = cfg
      @keyname = keyname
      setup
    end

    attr_reader :keyname
    def to_s
      public_key_link
    end
    def to_sym
      public_key_link.to_sym
    end
    def self.privkey_ipfs_dir
      @privkey_ipfs_dir ||= begin
        default_ipfs_dir = "#{ENV['HOME']}/.ipfs"
        privkey_base = ENV['IPFS_PATH'] || default_ipfs_dir
        "#{privkey_base}/keystore"
      end
    end

    def self.generate_key(name)
      unless File.exist?(privkey_ipfs_dir)
        raise StandardError, "can't find #{privkey_ipfs_dir}"
      end

      path = File.join(privkey_ipfs_dir, name)
      `ipfs key gen -t=rsa -s=4096 #{name}` unless File.exist?(path)
    end

    def self.import_or_create_privkey_from_keystore(name = 'self')
      generate_key(name)

      pubkey = `ipfs key list -l | grep #{name}`.split(' ').first

      privkey_ipfs_path = File.join(privkey_ipfs_dir, name)
      privkey_ipfs = Base64.strict_encode64(File.read(privkey_ipfs_path))

      private_key = `echo #{privkey_ipfs} | ipfs_keys_export`

      { private_key: private_key, public_key_ipfs: pubkey }
    end

    def mk_basedir
      return false if File.directory?(cfg.tictac_dir)
      STDERR.puts "CREATE\tTICTAC_DIR\t\t#{cfg.tictac_dir}"
      FileUtils.mkdir_p(cfg.tictac_dir)
      #      else
      #        STDERR.puts "EXISTS\t\TICTAC_DIR\t\t#{cfg.tictac_dir}"
    end

    def ipfs_config
      @ipfs_config ||= begin
        config_file = File.read(File.join(cfg.ipfs_path, 'config'))
        JSON.parse(config_file)
      end
    end

    def setup_keys
      if keyname == 'self'
        pubkey_ipfs = ipfs_config['Identity']['PeerID']
        key64 = ipfs_config['Identity']['PrivKey']
        private_key = `echo #{key64} | ipfs_keys_export`
        [private_key, pubkey_ipfs]
      else
        keys = Identity.import_or_create_privkey_from_keystore(keyname)
        [keys[:private_key], keys[:public_key_ipfs]]
      end
    end

    def write_keys(private_key, pubkey, pubkey_ipfs, pkey_openssl_ipfsaddr)
      File.write(private_path, private_key)
      File.write(pub_path, pubkey)
      File.write(ipfslink_path, pkey_openssl_ipfsaddr)
      File.write(ipfspub_path, pubkey_ipfs)
    end

    def generate_pkey_openssl_ipfsaddr(pubkey_ipfs, pkey_obj)
      Open3.popen3('ipfs add -Q') do |i, o, _e|
        i.write("#{pubkey_ipfs}\n" + pkey_obj.public_key.export)
        i.close
        o.read
      end.chomp
    end

    def setup
      mk_basedir

      private_key, pubkey_ipfs = setup_keys

      pkey_obj = OpenSSL::PKey::RSA.new(private_key)

      write_keys(
        private_key,
        pkey_obj.public_key.export,
        pubkey_ipfs,
        generate_pkey_openssl_ipfsaddr(pubkey_ipfs, pkey_obj)
      )

      #      STDERR.puts "IMPORTED\t#{keyname}"
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
      @public_key ||= File.read(File.join(tictac_dir, "#{@keyname}.ipfspub"))
    end

    def public_key_link
      @public_key_link ||= File.read(
        File.join(tictac_dir, "#{@keyname}.ipfslink")
      )
    end

    def private_key
      @private_key ||= OpenSSL::PKey::RSA.new(
        File.read(File.join(tictac_dir, "#{@keyname}.pem"))
      )
    end

    def empty_log
      'QmW2iRGLDBBTa4Rorfoj3rZ6bUfSfXRtPeJavjSUKs5CKN'
    end
  end

  class IpfsPathError < StandardError
  end
end
