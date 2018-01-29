require 'fileutils'
module TicTac
  IPFS_PATH=ENV['IPFS_PATH'] ? ENV['IPFS_PATH'] : File.absolute_path("#{ENV['HOME']}/.ipfs")
  Tictac_dir="#{IPFS_PATH}/tictac"
  Private_key="#{Tictac_dir}/self.pem"
  Empty_log="Qmc5m94Gu7z62RC8waSKkZUrCCBJPyHbkpmGzEePxy2oXJ"
end
