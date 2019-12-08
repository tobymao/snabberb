# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'snabberb/version'

Gem::Specification.new do |spec|
  spec.name          = 'snabberb'
  spec.version       = Snabberb::VERSION
  spec.authors       = ['Toby Mao']
  spec.email         = ['toby.mao@gmail.com']

  spec.summary       = 'A simple Opal view framework based on Snabbdom.'
  spec.description   = <<~DESCRIPTION
    Snabberb is a simple Opal view framework based on Snabbdom. You can write efficient reactive Javascript in pure Ruby. Snabberb provides a simple way to track state'}
  DESCRIPTION
  spec.homepage      = 'https://github.com/tobymao'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = %w[lib opal]

  spec.add_dependency 'opal', '~> 1.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'c_lexer'
  spec.add_development_dependency 'execjs'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.7'
end
