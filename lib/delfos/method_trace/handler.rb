# frozen_string_literal: true

require "binding_of_caller"
require_relative "code_location"
require_relative "eval_in_caller"
require "delfos/file_system"

module Delfos
  module MethodTrace
    Handler = Struct.new(:trace_point)

    class Handler
      include EvalInCaller

      def self.perform(trace_point)
        new(trace_point).perform
      end

      def relevant?
        FileSystem.include_file?(call_site.called_method_path)
      end

      STACK_OFFSET = 6

      def call_site
        @call_site ||= CodeLocation.new_callsite(
          file:        eval_in_caller("__FILE__", STACK_OFFSET),
          line_number: eval_in_caller("__LINE__", STACK_OFFSET),
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
