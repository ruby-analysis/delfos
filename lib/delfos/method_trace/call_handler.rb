# frozen_string_literal: true

require "delfos/call_stack"
require_relative "code_location"

module Delfos
  module MethodTrace
    CallHandler = Struct.new(:trace_point)

    class CallHandler
      def perform
        return unless relevant?

        CallStack.push(call_site)

        Delfos.call_site_logger.log(call_site)
      end

      def call_site
        @call_site ||= CodeLocation.callsite_from(
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
        Delfos.include_file?(call_site.called_method_path) &&
          Delfos.include_file?(call_site.container_method_path)
      end
    end
  end
end
