# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "lib/**/*_spec.rb"
  t.rspec_opts=["--profile 3"]
end

task default: :spec
