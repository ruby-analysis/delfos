# frozen_string_literal: true
require_relative "call_site_parsing"

module Delfos
  module MethodLogging
    class CodeLocation
      class << self
        def from_call_site(stack, call_site_binding)
          CallSiteParsing.new(stack, call_site_binding).perform
        end

        def from_called(object, called_method, class_method)
          begin
          file, line_number = called_method.source_location
          rescue Exception => e
            byebug
          end
          return unless file && line_number

          new(object: object, method_name: called_method.name.to_s,
              class_method: class_method, file: file, line_number: line_number)
        end

      end

      attr_reader :object, :method_name, :class_method, :line_number

      def initialize(object:, method_name:, class_method:, file:, line_number:)
        @object       = object
        @method_name  = method_name
        @class_method = class_method
        @line_number  = line_number.to_i
        @file         = file
      end

      def file
        relative_filename @file
      end

      def klass
        object.is_a?(Class) ? object : object.class
      end

      def method_definition_file
        relative_filename(method_definition&.first || fallback_method_definition_file)
      end

      def method_definition_line
        method_definition&.last&.to_i || fallback_method_definition_line_number
      end

      def method_type
        class_method ? "ClassMethod" : "InstanceMethod"
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

      def fallback_method_definition_file
        @file
      end

      def fallback_method_definition_line_number
        0
      end

      def method_definition
        @method_definition ||= Patching::MethodCache.find(klass: klass, method_name: method_name, class_method: class_method)&.source_location
      end
    end
  end
end
