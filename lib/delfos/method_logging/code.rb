# frozen_string_literal: true
require_relative "klass_determination"

module Delfos
  module MethodLogging
    class Code < Struct.new(:code_location)
      extend Forwardable
      delegate [:object, :method_type, :method_name, :line_number] => :code_location

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

    class CodeLocation < Struct.new(:object, :method_name, :method_type, :file, :line_number)
      include KlassDetermination

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

      def self.from_method(object, called_method, class_method)
        file, line_number = called_method.source_location

        new(object, called_method.name.to_s, class_method, file, line_number)
      end

      def klass
        klass_for(object)
      end
    end
  end
end
