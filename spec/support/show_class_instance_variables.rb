# frozen_string_literal: true

module ShowClassInstanceVariables
  class << self
    attr_accessor :last_executed_rspec_test
  end

  def self.variables_for(n)
    return unless n.is_a?(Module)

    display_variables(n)

    n.constants.each do |c|
      klass = relevant_constant_for(c, n)
      next unless klass

      display_variables(klass)

      handle_nesting(klass, n)
    end
  end

  def self.handle_nesting(klass, n)
    klass.constants.each do |k|
      k = klass.const_get(k)
      next if k == klass || k == n

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
        puts "non-nil class variable found after running #{self.last_executed_rspec_test}:\n  #{klass} #{iv}: #{val.inspect}"
      end
    end
  end
end
