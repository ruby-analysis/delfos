# frozen_string_literal: true
module Delfos
  module Patching
    MethodDefinition = Struct.new(:method_name, :class_method, :parameters) do
      def setup
        [<<-METHOD, __FILE__, __LINE__ + 1]
          def #{method_name}(#{parameters})

            call_site = Delfos::MethodLogging::CallSiteParsing.new(caller.dup).perform

            if call_site
              klass = self.is_a?(Module) ? self : self.class
              original_method = MethodCache.find(klass: klass, class_method: #{class_method}, method_name: #{method_name.inspect})

              if original_method
                Delfos::MethodLogging.log(call_site, self, original_method, #{class_method})
              else
                Delfos.logger.error("Method not found for \#{klass}, class_method: #{class_method}, method_name: #{method_name}")
              end
            end

            MethodOverride.with_stack(call_site) do
              super(#{parameters})
            end
          end
        METHOD
      end
    end
  end
end
