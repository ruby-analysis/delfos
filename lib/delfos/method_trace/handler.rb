# frozen_string_literal: true

require_relative "code_location"

module Delfos
  module MethodTrace
    Handler = Struct.new(:trace_point)

    class Handler
      def self.perform(trace_point)
        new(trace_point).perform
      end

      def relevant?
        Delfos.include_file?(call_site.called_method_path)
      end

      def call_site
        @call_site ||= CodeLocation.new_callsite(
          container_method: container_method,
          called_method:    called_method,
        )
      end

      def container_method
        @container_method ||= CodeLocation.new_container_method
      end

      def called_method
        @called_method ||= CodeLocation.new_method(
          object:       trace_point.self,
          method_name:  trace_point.method_id,
          file:         trace_point.path,
          line_number:  trace_point.lineno,
          class_method: trace_point.self.is_a?(Module),
        )
      end
    end
  end
end
