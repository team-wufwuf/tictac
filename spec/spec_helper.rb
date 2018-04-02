lib = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

RSpec.configure do |c|
  c.before(:all) do
    Timeout.timeout(20) do
      Kernel.loop do
        ipfs_info=JSON.parse(`ipfs id`,symbolize_names: true)
        ipfs_info[:Addresses].find do |address|
          address =~ /ip4/
        end && break
        sleep 1
      end
    end
    # need to release the locks on users between requests
    #    `ipfs repo fsck`
  end
end
