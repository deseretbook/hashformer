# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hash_mash/version'

Gem::Specification.new do |spec|
  spec.name          = "hash_mash"
  spec.version       = HashMash::VERSION
  spec.authors       = ['Deseret Book', 'Mike Bourgeous']
  spec.email         = ["mike@mikebourgeous.com"]
  spec.summary       = 'Mash any Hash with a declarative data transformation DSL'
  spec.description   = <<-DESC
    Hash Mash provides a simple, Ruby Hash-based way of transforming data from
    one format to another.  It's vaguely like XSLT, but way less complicated
    and way more Ruby.
    DESC
  spec.homepage      = "https://github.com/deseretbook/hash_mash"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_runtime_dependency "classy_hash", "~> 0.1", ">= 0.1.1"
end
