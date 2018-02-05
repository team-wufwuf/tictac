require_relative 'lib/identity'

begin
  TicTac::Identity.new.setup(ARGV[0])
rescue StandardError => e
  STDERR.puts e.message
  e.backtrace.each do |bt|
    STDERR.puts bt
  end
  exit 1
end
