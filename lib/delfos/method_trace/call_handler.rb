# frozen_string_literal: true

require "delfos/call_stack"
require_relative "code_location"
require_relative "code_location/eval_in_caller"

module Delfos
  module MethodTrace
    CallHandler = Struct.new(:trace_point)

    class CallHandler
      include CodeLocation::EvalInCaller

      def perform
        return unless relevant?

        CallStack.push(call_site)
      end

      STACK_OFFSET = 7

      def call_site
        @call_site ||= CodeLocation.callsite_from(
          file:             eval_in_caller("__FILE__", STACK_OFFSET),
          line_number:      eval_in_caller("__LINE__", STACK_OFFSET),
          container_method: container_method,
          called_method:    called_method,
        )
      end

      def container_method
        @container_method ||= CodeLocation.create_container_method
      end

      def called_method
        @called_method ||= CodeLocation.method_from(
          object:       trace_point.self,
          method_name:  trace_point.method_id,
          file:         trace_point.path,
          line_number:  trace_point.lineno,
          class_method: trace_point.self.is_a?(Module),
        )
      end

      private

      def relevant?
        Delfos.include_file?(call_site.called_method_path)
      end
    end
  end
end
