# frozen_string_literal: true
require_relative "klass_determination"

module Delfos
  module MethodLogging
    class Code
      extend Forwardable
      delegate [:object, :method_type, :method_name, :line_number, :method_definition_file,
                :method_definition_line] => :code_location

      attr_reader :code_location

      def initialize(code_location)
        @code_location = code_location
      end

      def self.from(stack, caller_binding, class_method)
        location = CodeLocation.from(stack, caller_binding, class_method)
        return unless location
        new location
      end

      def self.from_method(object, called_method, class_method)
        location = CodeLocation.from_method(object, called_method, class_method)
        return unless location
        new location
      end

      def file
        file = code_location.file.to_s

        if file
          Delfos.application_directories.map do |d|
            file = relative_path(file, d)
          end
        end

        file
      end

      def relative_path(file, dir)
        match = dir.to_s.split("/")[0..-2].join("/")

        if file[match]
          file = file.gsub(match, "").
                 gsub(%r{^/}, "")
        end

        file
      end

      def klass
        name = code_location.klass.name || "__AnonymousClass"
        name.tr ":", "_"
      end
    end

    # This magic number is determined based on the specific implementation now
    # E.g. if the line
    # where we call this `caller_binding.of_caller(stack_index + STACK_OFFSET).eval('self')`
    # is to be extracted into another method we will get a failing test and have to increment
    # the value
    STACK_OFFSET = 4

    class CodeLocation
      include KlassDetermination

      attr_reader :object, :method_name, :method_type, :file, :line_number

      def initialize(object, method_name, method_type, file, line_number)
        @object = object
        @method_name = method_name
        @method_type = method_type ? "ClassMethod" : "InstanceMethod"
        @file = file
        @line_number = line_number
      end

      def self.from(stack, caller_binding, class_method)
        current = stack.detect do |s|
          file = s.split(":")[0]
          Delfos::MethodLogging.include_file_in_logging?(file)
        end

        return unless current

        stack_index = stack.index { |c| c == current }

        object = caller_binding.of_caller(stack_index + STACK_OFFSET).eval("self")

        file, line_number, rest = current.split(":")
        method_name = rest[/`.*'$/]
        method_name = begin
                        method_name.delete("`").delete("'")
                      rescue
                        nil
                      end

        new(object, method_name.to_s, class_method, file, line_number.to_i)
      end

      def method_definition_file
        method_definition[0]
      end

      def method_definition_line
        method_definition[1]
      end

      def self.from_method(object, called_method, class_method)
        file, line_number = called_method.source_location

        new(object, called_method.name.to_s, class_method, file, line_number)
      end

      def klass
        klass_for(object)
      end

      private

      def method_definition
        @method_definition ||= object.method(method_name).source_location
      end
    end
  end
end
