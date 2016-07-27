# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hashformer/version'

Gem::Specification.new do |spec|
  spec.name          = "hashformer"
  spec.version       = Hashformer::VERSION
  spec.authors       = ['Deseret Book', 'Mike Bourgeous']
  spec.email         = ["mike@mikebourgeous.com"]
  spec.summary       = 'Transform any Hash with a declarative data transformation DSL for Ruby'
  spec.description   = <<-DESC
    Hashformer provides a simple, Ruby Hash-based way of transforming data from
    one format to another.  It's vaguely like XSLT, but way less complicated
    and way more Ruby.
    DESC
  spec.homepage      = "https://github.com/deseretbook/hashformer"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0'

  spec.add_runtime_dependency "classy_hash", "~> 0.1", ">= 0.1.1"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "simplecov", "~> 0.12.0"
  spec.add_development_dependency "codeclimate-test-reporter"
  spec.add_development_dependency "byebug", "~> 9.0" unless RUBY_PLATFORM == 'java'
  spec.add_development_dependency "activesupport", "~> 4.2"
end
