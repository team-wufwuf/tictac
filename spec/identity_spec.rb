require 'timeout'
require 'open3'
require 'spec_helper'
require 'ipfs/identity'
require 'ipfs/config'

RSpec.describe Ipfs::Identity do
  let(:tmp_dir) { ENV['TICTAC_TEST_DIR'] || File.join(__dir__, 'tmp') }

  let(:private_key) do
    priv = <<-PRIVATEKEY
      CAASpwkwggSjAgEAAoIBAQDYP5vLSgTjFWMGSGjtCzB2dTTVvzrWLBzEAcdE0UFxWxeKsoj+WJnnqKverh9355yeO5vSCZ2i+CdB2Vk403etabYEHkq7AVE0QA2qSYr/N3U3c80IkXDLWOc3Y8NJK1IlWOSahxz5++2TIEKD8ya5TwA9/tDcpVeE+DjkrWjMHhOeYywTRxLR81hvigofynt25VoLSsNIHeX90/3SMV5UwLSkxEwA9nKN26faB/FnnGlPRHmjgCMMwTyqjLzKn9mu00F5TuXhggLCa6vbLaWFJlaQm+phgdA9ErYgo/aVGwoQl6wgiyNn97NB60AfVZTyP30/LGdVO6WOkgFg7fQvAgMBAAECggEBALDYG/U8vBBlHg02TDCGNQS6xxGCCIC7pG6asbZSln04LGFtreCq3nn3k05RAUUScR9pyf0ThgmPfLM6Jt/09+smBwcJKr4RzrG3LDW1XOloFgDaP7OhFSgGtVezyzFcLxqBvrmsgwLghqIKALtdrq5er+kDKRU4VgFU6VoBgjFhajJ3GR4YPKB0hKDH7z0tOj02b4s7A+4gN6/RGKxc4BPsPOnya3wWfN1csPB8UIxLki8RwUDB9mWDg3OqRMzcBQGEDldrSDJWNe2cAAAQkQmwajR4w6/yLZ95RK9rJiFlrcBEz8Ku/fW7upQ3QU38MqiRmaLI8T4mRHZgrUsnDkkCgYEA4jIYYZem3I7+m3vqTOhNraxMStzKYaTPrI5FO1sjzj129pvB3Z2tmXb5cJpwdVypc/+Qnz3TNIV+X3omeYEJuSQtAnhlT5W1GSAU8/EWnfJdMDVgE/z0C214uC8t8xifW78aqjtfiNhHT/07vPRjxMl8VQ0eGj4YkobZrqP/a50CgYEA9L36xDD2LpFmnaPM1G4poeDafC3/TbMpvenkK/yaZdQx5gOf7UPqv/mU4IPC/AwJnHgM7MoN0tnFodgbIoKSW+qhIFXzkTJQxfHK3zwbC9LEAsCd0YH7m6N8Vpo/GX+0FPeJwryx5NB18euxt3cYTyUz2rQXHliynKnudlzJkzsCgYBHJcaxe8gKfBftxC5QfolgZV+h9Izb5cFE34M7RlGe34p5y0hRcvVV3ixblNhmsfzC9dIBpKq4TH0RfxR3B3WNfKmDq2cCf251NrggeubIS6GwNjnAT8JbjdV46a4kVsxZSWUTwpUsMAtOR7LwnlZ7YXzwK64aRwnnnO7/laoTqQKBgCRC2Zqj3nW72UZV9I0s3UI8vGJVtlPezbpzovjZbk7UB6iatOFEhM14vxQcsZECf5INP2z96tpopZ17FVohmmm/86uE0JecqtcJIhO9Jgy0Z5I406ks5wiCSnPSWrL+dsH8gw61Qm4ybKcxUp1qKdHgIzSuJha68YvAqbIjwUHtAoGAdbs3yJsGEos85CwNQ8aO0/4r6dxoFxKHrrlLmYY9ZgWk6z/flUIQ/hXqglLAKksHGs7TwFbkJ012O0NdZvFFSGdX9b768H1J8HeBaIbT5E3fsqpEvAFYL65iri6mJIV0y+t03hBy9ptWnXomy12Jp3J+Z77I2eRwlOXoZmksEPo=
    PRIVATEKEY
    priv.chomp
  end

  let(:identity_string) do
    JSON.generate(
      Identity: {
        PeerID: 'QmWvoxpyC3DjjA5Ehy8wvmhoXhbrxgHLiNbFVCvHjneSLc',
        PrivKey: private_key
      }
    )
  end

  before(:all) do
    swarm_port = 4061
    api_port = 5061
    gateway_port = 8090

    @tmp_dir = ENV['TICTAC_TEST_DIR'] || File.join(__dir__, 'tmp')
    @cfg = Ipfs::Config.new(@tmp_dir)

    puts @tmp_dir

    config_file = JSON.parse(File.open("#{@tmp_dir}/config").read)
    config_file['Addresses']['Swarm'][0] = "/ip4/127.0.0.1/tcp/#{swarm_port}"
    config_file['Addresses']['API'] = "/ip4/127.0.0.1/tcp/#{api_port}"
    config_file['Addresses']['Gateway'] = "/ip4/127.0.0.1/tcp/#{gateway_port}"

    File.write("#{@tmp_dir}/config", JSON.dump(config_file))

    @external_ipfs = false
    begin
      ipfs_info = JSON.parse(`ipfs -c "#{@tmp_dir}" id`)

      unless ipfs_info['Addresses'].nil?
        puts 'external client detected'
        @external_ipfs = true
      end
    rescue StandardError
      puts 'no client detected'
    end

    unless @external_ipfs
      @ipfs_proc = Open3.popen3("ipfs -c #{@tmp_dir} daemon 2>&1")
      Timeout.timeout(20) do
        Kernel.loop do
          line = @ipfs_proc[1].readline
          puts line
          (line =~ /Daemon is ready/) && break
        end
      end
    end
  end

  after(:all) do
    unless @external_ipfs
      Process.kill('KILL', @ipfs_proc[3].pid)
      sleep 1
      Process.kill('KILL', @ipfs_proc[3].pid + 1)
    end
  end

  it 'generates the files' do
    Ipfs::Identity.new('self', @cfg)
    expect(File.exist?(File.join(tmp_dir, 'tictac', 'self.pem'))).to be true
    expect(File.exist?(File.join(tmp_dir, 'tictac', 'self.pub'))).to be true
    expect(
      File.exist?(File.join(tmp_dir, 'tictac', 'self.ipfspub'))
    ).to be true
    expect(
      File.exist?(File.join(tmp_dir, 'tictac', 'self.ipfslink'))
    ).to be true
  end

  it 'produces a signed link' do
    id = Ipfs::Identity.new('foo', @cfg)
    Ipfs::Identity.resolve_public_key_link(id.public_key_link)
  end
end
