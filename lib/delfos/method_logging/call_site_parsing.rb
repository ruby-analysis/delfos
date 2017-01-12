# frozen_string_literal: true
require "binding_of_caller"

module Delfos
  module MethodLogging
    class CallSiteParsing
      # This magic number is based on the implementation within this file.
      # If the line with `binding.of_caller(stack_offset).receiver`
      # is moved up or down the call stack a test fails and we have to change `STACK_OFFSET`
      STACK_OFFSET = 4

      attr_reader :stack

      def initialize(stack, stack_offset: nil)
        @stack             = stack
        @stack_offset      = stack_offset
      end

      def perform
        caller_object
        return unless file && line_number && method_name

        CodeLocation.new(object: caller_object,
                         method_name: method_name.to_s,
                         class_method: class_method,
                         file: file,
                         line_number: line_number)
      end

      private

      def class_method
        caller_object.is_a? Module
      end

      def stack_offset
        @stack_offset ||= STACK_OFFSET
      end

      def caller_binding
        @caller_binding ||= binding.of_caller(stack_offset)
      end

      def method_name
        @method_name ||= caller_binding.eval "__method__"
      end

      def caller_object
        @caller_object ||= caller_binding.receiver
      end

      def file
        @file ||= caller_binding.eval "__FILE__"
      end

      def line_number
        @line ||= caller_binding.eval "__LINE__"
      end

      def original_method
        @original_method ||= Delfos::Patching::MethodCache.find(
          klass: klass,
          method_name: method_name,
          class_method: class_method)
      end

      def klass
        caller_object.is_a?(Module) ?  caller_object : caller_object.class
      end
    end
  end
end
