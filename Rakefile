# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "lib/**/*_spec.rb,spec/**/*_spec.rb"
  if ENV["CI"]
    t.rspec_opts = ["-r rspec_junit_formatter",
                    "--format progress",
                    "--format RspecJunitFormatter",
                    "-o $CIRCLE_TEST_REPORTS/rspec/junit.xml"]
  end
end

load "ext/delfos/file_system/pathname/compile.rake"

task default: %i[compile spec]
