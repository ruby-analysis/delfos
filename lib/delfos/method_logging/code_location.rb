# frozen_string_literal: true
module Delfos
  module MethodLogging
    class CodeLocation
      attr_reader :object, :file, :line_number

      def initialize(object:, method_name:, file:, line_number:)
        @object       = object
        @method_name  = method_name
        @file         = file
        @line_number  = line_number.to_i
      end

      def klass
        object.is_a?(Class) ? object : object.class
      end

      def file
        relative_filename(@file)
      end

      def method_name
        @method_name.to_s
      end

      def method_type
        klass.instance_methods(false).include?(@method_name) ? "InstanceMethod" : "ClassMethod"
      end

      private

      def relative_filename(f)
        return unless f
        file = f.to_s

        Delfos.application_directories.map do |d|
          file = relative_path(file, d)
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
    end
  end
end
