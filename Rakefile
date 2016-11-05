# frozen_string_literal: true

begin
  require "bundler/gem_tasks"
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = "lib/**/*_spec.rb"
  end

  task default: :spec

rescue LoadError
end
