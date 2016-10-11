module Delfos
  module Specs
    module Inheritance
      class A
        def self.a_class_method_to_be_inherited
          super
        end

        def a_method_to_be_inherited
          super
        end
      end

      class B < A
        def self.inherited(klass)
          return if klass
        end
      end


      class C < B
      end
    end
  end
end
