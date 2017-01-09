# frozen_string_literal: true
require "binding_of_caller"

module Delfos
  module MethodLogging
    class CallSiteParsing
      # This magic number is based on the implementation within this file.
      # If the line with `binding.of_caller(stack_index + STACK_OFFSET).receiver`
      # is moved up or down the call stack a test fails and we have to change `STACK_OFFSET`
      STACK_OFFSET = 3

      attr_reader :stack

      def initialize(stack, stack_offset: nil)
        @stack             = stack
        @stack_offset      = stack_offset
      end

      def perform
        file, line_number, method_name = method_details
        return unless first_relevant_stack_trace_item && file && line_number && method_name

        CodeLocation.new(object: object,
                         method_name: method_name.to_s,
                         class_method: class_method,
                         file: file,
                         line_number: line_number)
      end

      private

      def class_method
        object.is_a? Module
      end

      def first_relevant_stack_trace_item
        stack.detect do |s|
          file = s.split(":")[0]
          Delfos::MethodLogging.include_file?(file)
        end
      end

      def object
        @object ||= binding.of_caller(stack_index + stack_offset).receiver
      end

      def stack_offset
        @stack_offset ||= STACK_OFFSET
      end

      def stack_index
        stack.index { |c| c == first_relevant_stack_trace_item }
      end

      METHOD_NAME_REGEX = /`(.*)'$/

      def method_details
        return unless first_relevant_stack_trace_item
        file, line_number, rest, more = first_relevant_stack_trace_item.split(":")

        rest = more.nil? ? rest : "#{rest}:#{more}"
        method_name = rest.match(METHOD_NAME_REGEX)&.[](1)

        return unless method_name && file && line_number

        [file, line_number.to_i, method_name]
      end
    end
  end
end
