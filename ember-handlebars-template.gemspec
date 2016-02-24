lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ember/handlebars/version'

Gem::Specification.new do |spec|
  spec.name          = 'ember-handlebars-template'
  spec.version       = Ember::Handlebars::VERSION
  spec.authors       = ['Ryunosuke SATO']
  spec.email         = ['tricknotes.rs@gmail.com']

  spec.summary       = %q{The sprockets template for Ember Handlebars.}
  spec.description   = %q{The sprockets template for Ember Handlebars.}
  spec.homepage      = 'https://github.com/tricknotes/ember-handlebars-template'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'sprockets', '>= 3.3', '< 4'
  spec.add_dependency 'barber', '>= 0.11.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'handlebars-source'
  spec.add_development_dependency 'minitest'
end
