# frozen_string_literal: true
module Delfos
  module Patching
    module DetermineConstant
      def constant_from(val, klass)
        constant_name = val.to_a.last
        klass_namespaces = klass.name.split("::")
        namespace = klass_namespaces.shift(klass_namespaces.length - 1).join("::")
        namespace = Object.const_get namespace

        constant = namespace.const_get(constant_name)

        if constant.is_a?(Module)
          constant.name
        else
          "#{namespace}::#{constant_name}"
        end
      end
    end
  end
end
