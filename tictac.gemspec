# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'tictac'
  spec.version       = 0.1
  spec.authors       = ['Joe']
  spec.email         = ['joe@joeseggfarm.com']
  spec.summary       = 'As above, so below'
  spec.description   = 'IPFS stuff and incidental tictactoe'
  spec.homepage      = 'https://github.com/team-wufwuf/tictac'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.54'

  spec.add_dependency 'ipfs'
  spec.add_dependency 'openssl'
end
