require_relative 'lib/identity'

begin
  TicTac::Identity.new.setup
rescue StandardError => e
  puts e.message
  e.backtrace.each do |bt|
    puts bt
  end
  exit 1
end
