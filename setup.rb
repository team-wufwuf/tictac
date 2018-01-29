require 'open3'
require 'json'
require 'openssl'
require_relative 'lib/config'

module TicTac
  def self.setup
    if !File.directory?(cfg.ipfs_path)
      puts "ERROR\tPATH_DNE\t\t#{cfg.ipfs_path}"
      exit 1
    end

    if !File.directory?(cfg.tictac_dir)
      puts "CREATE\tTICTAC_DIR\t\t#{cfg.tictac_dir}"
      FileUtils.mkdir_p(cfg.tictac_dir)
    else
      puts "EXISTS\t\TICTAC_DIR\t\t#{cfg.tictac_dir}"
    end

    private_key_file = File.join(cfg.tictac_dir, 'self.pem')

    if File.file?(private_key_file)
      puts "EXISTS\tTICTAC_PRIVKEY\t\t#{cfg.tictac_dir}/self.pem"
    else
      begin
        config_file = File.read(File.join(cfg.ipfs_path, 'config'))
        ipfs_config = JSON.load(config_file)

        privkey_ipfs = ipfs_config["Identity"]["PrivKey"]
        pubkey_ipfs  = ipfs_config["Identity"]["PeerID"]

        private_key = %x(echo #{privkey_ipfs} | ipfs_keys_export)
        File.write(private_key_file, private_key)

        pkey_obj = OpenSSL::PKey::RSA.new(File.read(private_key_file))

        File.write(File.join(cfg.tictac_dir, "self.pub"), pkey_obj.public_key.export)

        pkey_openssl_ipfsaddr = Open3.popen3("ipfs add -Q") do |i,o,e|
          i.write("#{pubkey_ipfs}\n" + pkey_obj.public_key.export)
          i.close
          o.read
        end.chomp

        File.write(File.join(cfg.tictac_dir, "pubkey.ipfslink"), pkey_openssl_ipfsaddr)
        File.write(File.join(cfg.tictac_dir, "self.ipfspub"), pubkey_ipfs)
      rescue StandardError  => e
        puts "ERROR\tPRIVKEY_IMPORT\t#{e}"
      else
        puts "IMPORTED\tself"
      end
    end
  end
end
TicTac.setup
