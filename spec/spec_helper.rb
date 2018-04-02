lib = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

RSpec.configure do |c|
  c.before do
    # need to release the locks on users between requests
    #    `ipfs repo fsck`
  end
end
