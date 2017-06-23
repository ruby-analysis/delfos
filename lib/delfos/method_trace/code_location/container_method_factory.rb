# frozen_string_literal: true

require "delfos/method_trace/code_location"

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
          # ensure memoised with correct stack offset
          method_object
          source_location

          CodeLocation.method_from(attrs)
        end

        private

        def attrs
          {
            object:        object,
            method_name:   method_name,
            file:          file,
            line_number:   line,
            class_method:  class_method,
            method_object: method_object,
            super_method:  super_method,
          }
        end

        def class_method
          return @class_method if defined?(@class_method)

          @class_method = object.is_a?(Module)
        end

        def file
          return @file if defined? @file

          @file = source_location&.first
        end

        def line
          return @line if defined? @line

          @line = source_location&.last
        end

        def source_location
          return @source_location if defined? @source_location

          @source_location =
            method_object&.source_location ||
            eval_in_caller("[__FILE__, __LINE__]", stack_offset)
        end

        REPRESENTATION_OF_MAIN = Object.new

        def object
          @object ||= method_object&.receiver || REPRESENTATION_OF_MAIN
        end

        def method_name
          @method_name ||= method_object&.name
        end

        def super_method
          method_object&.super_method
        end

        RUBY_METHOD = "method(__method__) if __method__"

        def method_object
          return @method_object if defined? @method_object
          @method_object = eval_in_caller(RUBY_METHOD, stack_offset)
        end
      end
    end
  end
end
