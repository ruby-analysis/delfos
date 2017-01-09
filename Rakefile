# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "lib/**/*_spec.rb"
end

load "ext/delfos/file_system/pathname/compile.rake"

task default: [:compile, :spec]
