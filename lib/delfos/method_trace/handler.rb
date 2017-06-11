require "binding_of_caller"
require "delfos/code_location/call_site"
require "delfos/code_location/method"
require "delfos/call_stack"
require "delfos/app_directories"
require "delfos/method_trace/eval_in_caller"
require "delfos/method_trace/container_method"

module Delfos
  class MethodTrace
    Handler = Struct.new(:trace_point) do
      include EvalInCaller

      def self.perform(trace_point)
        new(trace_point).perform
      end

      private

      def relevant?
        AppDirectories.include_files?(
          call_site.raw_path,
          call_site.container_method_path,
          call_site.called_method_path
        )
      end

      STACK_OFFSET = 5

      def call_site
        @call_site ||= CodeLocation::CallSite.new(
          file:        eval_in_caller("__FILE__", STACK_OFFSET),
          line_number: eval_in_caller("__LINE__", STACK_OFFSET),
          container_method: container_method,
          called_method:    called_method
        )
      end

      def container_method
        @container_method ||= ContainerMethod.new.determine
      end

      def called_method
        @called_method ||= CodeLocation::Method.new(
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
