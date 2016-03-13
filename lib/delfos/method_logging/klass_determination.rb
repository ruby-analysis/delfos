# frozen_string_literal: true
module Delfos
  module MethodLogging
    module KlassDetermination
      private

      def klass_for(object)
        if object.is_a?(Class)
          object
        else
          object.class
        end
      end
    end
  end
end
