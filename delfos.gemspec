# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "delfos"
  spec.version       = "0.0.2-rc3"
  spec.authors       = ["Mark Burns"]
  spec.email         = ["markthedeveloper@gmail..com"]

  spec.summary       = "Runtime type analysis"
  spec.description   = "Record every method call, call-site, arguments and their types in your application code"
  spec.homepage      = "https://github.com/markburns/delfos"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.3.0"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.bindir        = "exe"

  spec.files = `git ls-files`.split("\n").reject{|l| l[/_spec\.rb|^spec\//] }.select{|l| l[/^lib|^exe/]}

  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "binding_of_caller", ">= 0.7.0"

  spec.add_development_dependency 'simplecov', '~> 0'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.2', '>= 0.2.3'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 1.0.8'
  spec.add_development_dependency 'webmock', '~> 2.3', '>= 2.3.2'
  spec.add_development_dependency 'rake-compiler', '~> 0'
  spec.add_development_dependency "pry-byebug", "~> 3.4", ">= 3.4.0"
  spec.add_development_dependency "rake", "~> 11.3.0", ">= 11.3.0"
  spec.add_development_dependency "rspec", "~>3.8.0"
end
