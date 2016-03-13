# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "binding_of_caller"

class BasicObject
  def dbg(variable_name = nil)
    puts
    puts

    puts ">" * 80
    puts caller[0]
    puts
    other_binding = binding.of_caller(1)

    vars =
      other_binding.eval("local_variables") +
      other_binding.eval("instance_variables")

    variable_name ||= vars.
                      reject { |v| v == :_ }.
                      detect { |v| other_binding.eval(v.to_s) == self }

    if variable_name
      puts "#{variable_name}: #{inspect}"
    else
      puts inspect
    end

    puts "<" * 80

    self
  end
end
require "byebug"

RSpec.configure do |c|
  c.before(:each) do
    require_relative "../lib/delfos"
    Delfos.reset!
  end

  c.after(:each) do
    require_relative "../lib/delfos"
    Delfos.reset!
  end
end
