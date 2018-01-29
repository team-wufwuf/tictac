require 'fileutils'
module TicTac
  IPFS_PATH=ENV['IPFS_PATH'] ? ENV['IPFS_PATH'] : File.absolute_path("#{ENV['HOME']}/.ipfs")
  Tictac_dir="#{IPFS_PATH}/tictac"
  Private_key=OpenSSL::PKey::RSA.new(File.read("#{Tictac_dir}/self.pem")) unless !File.exist? ("#{Tictac_dir}/self.pem")
  Empty_log="QmW2iRGLDBBTa4Rorfoj3rZ6bUfSfXRtPeJavjSUKs5CKN"
  Ipfs_public_key=File.read("#{Tictac_dir}/self.ipfspub") unless !File.exist? ("#{Tictac_dir}/self.pem")
  Ipfs_public_key_link=File.read("#{Tictac_dir}/pubkey.ipfslink")
end
