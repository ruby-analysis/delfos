# frozen_string_literal: true

module Delfos
  module Patching
    class ParameterExtraction
      attr_reader :meth

      def initialize(meth)
        @meth = meth
      end

      def required_args
        select_parameters(:req)
      end

      def parameters
        meth.parameters
      end

      private

      def parameters_to_string(parameters)
        optional  = select_parameters(:opt)
        key_rest  = select_parameters(:keyrest)
        rest      = select_parameters(:rest)

      end

      def select_parameters(type)
        parameters.select{|t, name| type == t } .map(&:last)
      end
    end
  end
end
