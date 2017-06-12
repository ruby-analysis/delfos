# frozen_string_literal: true
require_relative "filename_helpers"

module Delfos
  module CodeLocation
    class CallSite
      include FilenameHelpers
      attr_reader :line_number, :container_method, :called_method

      def initialize(file:, line_number:, container_method:, called_method:)
        @file             = file
        @line_number      = line_number.to_i

        @container_method = container_method
        @called_method    = called_method
      end

      def paths
        [raw_path, container_method_path, called_method_path]
      end

      def container_method_path
        container_method.raw_path
      end

      def called_method_path
        called_method.raw_path
      end

      def to_s
        "#<#{self.class.name} file: #{file}, line_number: #{line_number}, container_method: #{container_method}, called_method: #{called_method}>"
      end
    end
  end
end
