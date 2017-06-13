# frozen_string_literal: true

require "rake/extensiontask"
gemspec = Gem::Specification.load("delfos.gemspec")

Rake::ExtensionTask.new do |ext|
  ext.name = "pathname"
  ext.ext_dir = "ext/delfos/file_system/pathname"
  ext.lib_dir = "lib/delfos/file_system"
  ext.gem_spec = gemspec
end
