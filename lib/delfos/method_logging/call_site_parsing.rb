# frozen_string_literal: true
require "binding_of_caller"

module Delfos
  module MethodLogging
    class CallSiteParsing
      # This magic number is based on the implementation within this file.
      # If the line with `call_site_binding.of_caller(stack_index + STACK_OFFSET).receiver`
      # is moved up or down the call stack a test fails and we have to change `STACK_OFFSET`
      STACK_OFFSET = 5

      attr_reader :stack, :call_site_binding

      def initialize(stack, call_site_binding, stack_offset: nil)
        @stack             = stack
        @call_site_binding = call_site_binding
        @stack_offset      = stack_offset
      end

      def perform
        file, line_number, method_name = method_details
        return unless current && file && line_number && method_name

        CodeLocation.new(object, method_name.to_s, class_method, file, line_number)
      end

      private

      def class_method
        object.is_a? Module
      end

      def current
        stack.detect do |s|
          file = s.split(":")[0]
          Delfos::MethodLogging.include_file?(file)
        end
      end

      def object
        @object ||= call_site_binding.of_caller(stack_index + stack_offset).receiver
      end

      def stack_offset
        @stack_offset ||= STACK_OFFSET
      end

      def stack_index
        stack.index { |c| c == current }
      end

      METHOD_NAME_REGEX = /`.*'$/
      def method_details
        return unless current
        file, line_number, rest, more = current.split(":")

        method_name = if more.nil?
                        rest[METHOD_NAME_REGEX]
                      else
                        "#{rest}:#{more}"[METHOD_NAME_REGEX]
                      end

        return unless method_name && file && line_number

        method_name.delete!("`").delete!("'")

        [file, line_number.to_i, method_name]
      end
    end
  end
end
