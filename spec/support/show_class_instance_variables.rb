# frozen_string_literal: true

module ShowClassInstanceVariables
  class << self
    attr_accessor :last_executed_rspec_test
  end

  def self.variables_for(namespace)
    return unless namespace.is_a?(Module)
    return if namespace.ancestors.include? Struct

    display_variables(namespace)

    namespace.constants.each do |c|
      klass = relevant_constant_for(c, namespace)
      next unless klass

      display_variables(klass)

      handle_nesting(klass, namespace)
    end
  end

  def self.handle_nesting(klass, namespace)
    klass.constants.each do |k|
      k = klass.const_get(k)
      next if (k == klass) || (k == namespace)

      variables_for(k)
    end
  end

  def self.relevant_constant_for(c, namespace)
    return if namespace == c
    klass = namespace.const_get(c)

    return unless klass.is_a?(Module)
    return unless klass.name[namespace.name]
    klass
  end

  def self.display_variables(klass)
    return unless klass.instance_variables.length.positive?

    klass.instance_variables.each do |iv|
      val = klass.instance_eval(iv.to_s)

      unless val.nil?
        puts "non-nil class variable found after running #{last_executed_rspec_test}:\n  #{klass} #{iv}: #{val.inspect}"
      end
    end
  end
end

RSpec.configure do |c|
  c.before(:each) do |_e|
    ShowClassInstanceVariables.variables_for(Delfos)
  end

  c.after(:each) do |e|
    ShowClassInstanceVariables.last_executed_rspec_test = e.location
  end
end
