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
        privkey_ipfs=JSON.load(config_file)["Identity"]["PrivKey"]
        private_key=%x(echo #{privkey_ipfs} | ipfs_keys_export)
        File.write("#{Tictac_dir}/self.pem",private_key)
        pkey_obj=OpenSSL::PKey::RSA.new(File.read("#{Tictac_dir}/self.pem"))
        File.write("#{Tictac_dir}/self.pub",pkey_obj.public_key.export)
      rescue Exception  => e
        puts "ERROR\tPRIVKEY_IMPORT\t#{e}"
      end
      puts "IMPORTED\tself"
    end
  end
end
TicTac.setup
