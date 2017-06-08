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
        @method_name.to_s
      end

      def method_type
        class_method ? "ClassMethod" : "InstanceMethod"
      end

      def to_s
        "#<#{self.class.name} klass: #{klass}, line_number: #{line_number}, file: #{file}, method_name: #{method_name}>"
      end
    end
  end
end
