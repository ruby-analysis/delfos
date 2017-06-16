# frozen_string_literal: true

require_relative "eval_in_caller"
require_relative "filename_helpers"

module Delfos
  module MethodTrace
    module CodeLocation
      class ContainerMethodFactory
        include EvalInCaller
        include FilenameHelpers
        STACK_OFFSET = 12
        attr_reader :stack_offset

        def self.create(stack_offset: STACK_OFFSET)
          new(stack_offset: stack_offset).create
        end

        def initialize(stack_offset:)
          @stack_offset = stack_offset
        end

        def create
          # ensure evaluated and memoised with correct stack offset
          class_method

          CodeLocation.method_from(
            object:       object,
            method_name:  meth,
            file:         file,
            line_number:  line,
            class_method: class_method,
          )
        end

        private

        def object
          @object ||= eval_in_caller("self", stack_offset)
        end

        def class_method
          return @class_method if defined?(@class_method)

          @class_method = eval_in_caller("is_a?(Module)", STACK_OFFSET)
        end

        RUBY_IS_MAIN                = "self.class == Object && self&.to_s == 'main' && __method__.nil?"
        RUBY_SOURCE_LOCATION        = "(__method__).source_location if __method__"
        RUBY_CLASS_METHOD_SOURCE    = "method#{RUBY_SOURCE_LOCATION}"
        RUBY_INSTANCE_METHOD_SOURCE = "self.class.instance_method#{RUBY_SOURCE_LOCATION}"

        def method_finder
          @method_finder ||= class_method ? RUBY_CLASS_METHOD_SOURCE : RUBY_INSTANCE_METHOD_SOURCE
        end

        def file
          @file ||= eval_in_caller("(#{RUBY_IS_MAIN}) ? __FILE__ : ((#{method_finder})&.first)", stack_offset)
        end

        def line
          @line ||= eval_in_caller("(#{RUBY_IS_MAIN}) ? __LINE__ : ((#{method_finder})&.last)", stack_offset)
        end

        def meth
          @meth ||= eval_in_caller("__method__", stack_offset)
        end
      end
    end
  end
end
