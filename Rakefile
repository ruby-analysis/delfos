# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rake/extensiontask'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "lib/**/*_spec.rb"
end

gemspec = Gem::Specification.load('delfos.gemspec')

Rake::ExtensionTask.new do |ext|
  ext.name = 'delfos_pathname'
  ext.ext_dir = 'ext/delfos/pathname'
  #ext.lib_dir = 'lib/delfos/file_system'
  ext.gem_spec = gemspec
end

task :default => [:compile, :spec]
