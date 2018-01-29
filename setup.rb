require 'open3'
require 'json'
require 'openssl'
require_relative 'tictac'
module TicTac
  def self.setup
    if !File.directory?(IPFS_PATH)
      puts "ERROR\tPATH_DNE\t\t#{IPFS_PATH}"
      exit 1
    end
    if !File.directory?(Tictac_dir)
      puts "CREATE\tTICTAC_DIR\t\t#{Tictac_dir}"
      FileUtils.mkdir_p(Tictac_dir)
    else
      puts "EXISTS\t\TICTAC_DIR\t\t#{Tictac_dir}"
    end
    if File.file?("#{Tictac_dir}/self.pem")
      puts "EXISTS\tTICTAC_PRIVKEY\t\t#{Tictac_dir}/self.pem"
    else
      begin
        config_file=File.read("#{IPFS_PATH}/config")
        ipfs_config=JSON.load(config_file)
        privkey_ipfs=ipfs_config["Identity"]["PrivKey"]
        pubkey_ipfs=ipfs_config["Identity"]["PeerID"]
        private_key=%x(echo #{privkey_ipfs} | ipfs_keys_export)
        File.write("#{Tictac_dir}/self.pem",private_key)
        pkey_obj=OpenSSL::PKey::RSA.new(File.read("#{Tictac_dir}/self.pem"))
        File.write("#{Tictac_dir}/self.pub",pkey_obj.public_key.export)
        pkey_openssl_ipfsaddr=Open3.popen3("ipfs add -Q") do |i,o,e|
          i.write("#{pubkey_ipfs}\n"+pkey_obj.public_key.export);i.close;o.read
        end.chomp
        File.write("#{Tictac_dir}/pubkey.ipfslink",pkey_openssl_ipfsaddr)
        File.write("#{Tictac_dir}/self.ipfspub",pubkey_ipfs)
      rescue Exception  => e
        puts "ERROR\tPRIVKEY_IMPORT\t#{e}"
      end
      puts "IMPORTED\tself"
    end
    
  end
end
TicTac.setup
