# frozen_string_literal: true

require "bundler/gem_tasks"

task :all_specs do
  files = ARGV.length == 0 ?  Dir.glob("lib/**/*_spec.rb") : ARGV

  results = files.map do |f|
    puts "Running specs: #{f}"
    result = `rspec #{f} --color --require spec_helper`
  end
  puts results
end

task :default => :all_specs


