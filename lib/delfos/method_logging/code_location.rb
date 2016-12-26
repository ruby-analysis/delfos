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
          file, line_number = called_method.source_location
          return unless file && line_number

          new(object, called_method.name.to_s, class_method, file, line_number)
        end

        def method_type_from(class_method)
          class_method ? "ClassMethod" : "InstanceMethod"
        end
      end

      attr_reader :object, :method_name, :class_method, :method_type, :line_number

      def initialize(object, method_name, class_method, file, line_number)
        @object       = object
        @method_name  = method_name
        @class_method = class_method
        @method_type  = self.class.method_type_from class_method
        @line_number  = line_number.to_i
        @file         = file
      end

      def file
        file = @file.to_s

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
        object.is_a?(Class) ? object : object.class
      end

      def klass_name
        name = klass.name || "__AnonymousClass"
        name.tr ":", "_"
      end

      def method_definition_file
        if method_definition
          method_definition[:file]
        else
          "#{@file} method definition not found"
        end
      end

      def method_definition_line
        if method_definition
          method_definition[:line_number].to_i
        else
          0
        end
      end

      private

      def method_key
        "#{method_type}_#{method_name}"
      end

      def method_definition
        @method_definition ||= Patching::MethodCache.find(klass, method_key)
      end
    end

  end
end
