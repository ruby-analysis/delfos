# frozen_string_literal: true
require_relative "filename_helpers"

module Delfos
  module CodeLocation
    class Method
      include FilenameHelpers
      attr_reader :object, :method_name, :line_number, :class_method

      def initialize(object:, method_name:, file:, line_number:, class_method:)
        @object       = object
        @method_name  = method_name
        @file         = file
        @line_number  = line_number
        @class_method = class_method
      end

      def klass
        object.is_a?(Module) ? object : object.class
      end

      def method_name
        (@method_name || "(main)").to_s
      end

      def method_type
        class_method ? "ClassMethod" : "InstanceMethod"
      end

      def summary(reverse: false)
        summary = [source_location, method_summary ]

        (reverse ? summary.reverse : summary).join " "
      end

      private

      def method_summary
        "#{klass}#{separator}#{method_name}"
      end

      def source_location
        "#{file}:#{line_number}"
      end


      def separator
        class_method ? "." : "#"
      end
    end
  end
end
