# frozen_string_literal: true
module ShowClassInstanceVariables
  def self.variables_for(n)
    return unless n.is_a?(Class) || n.is_a?(Module)

    display(n)

    n.constants.each do |c|
      next if n == c

      klass = n.const_get(c)

      next unless klass.is_a?(Class) || klass.is_a?(Module)
      next unless klass.name[n.name]

      display(klass)

      klass.constants.each do |s|
        s = klass.const_get(s)
        next if s == klass || s == n

        variables_for(s)
      end
    end
  end

  def self.display(klass)
    if klass.instance_variables.length.positive?
      klass.instance_variables.each do |iv|
        val = klass.instance_eval(iv.to_s)

        unless val.nil?
          puts "non-nil class variable found:\n  #{klass} #{iv}: #{val.inspect}"
        end
      end
    end
  end
end
