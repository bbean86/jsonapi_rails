# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jsonapi_rails/version'

Gem::Specification.new do |spec|
  spec.name          = "jsonapi_rails"
  spec.version       = JsonapiRails::VERSION
  spec.authors       = ["Ben Bean"]
  spec.email         = ["bbean86@gmail.com"]

  spec.summary       = %q{Provides helpers for Rails applications that conform to the JSONAPI spec}
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  unless spec.respond_to?(:metadata)
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "hash_validator"
  spec.add_dependency "json_api_ruby"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "activerecord", "~> 3.2"
  spec.add_development_dependency "activesupport", "~> 3.2"
  spec.add_development_dependency "railties", "~> 3.2"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sqlite3"
end
