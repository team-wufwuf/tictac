require_relative 'lib/ipfs/identity'

begin
  Ipfs::Identity.new(ARGV[0])
rescue StandardError => e
  STDERR.puts e.message
  e.backtrace.each do |bt|
    STDERR.puts bt
  end
  exit 1
end
