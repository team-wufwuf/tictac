require 'fileutils'
module TicTac
  IPFS_PATH=ENV['IPFS_PATH'] ? ENV['IPFS_PATH'] : File.absolute_path("#{ENV['HOME']}/.ipfs")
  Tictac_dir="#{IPFS_PATH}/tictac"
  Private_key="#{Tictac_dir}/self.pem"
  Public_key="#{Tictac_dir}/self.pub"
  Empty_log="QmbJWAESqCsf4RFCqEY7jecCashj8usXiyDNfKtZCwwzGb"
end
