# frozen_string_literal: true
require_relative "../../delfos"
require_relative "../common_path"
require_relative "./added_methods"

module Delfos
  module MethodLogging
    class Args
      attr_reader :block

      def initialize(arguments)
        @raw_args = arguments.args
        @raw_keyword_args = arguments.keyword_args
        @block = arguments.block
      end

      def args
        @args ||= calculate_args(@raw_args)
      end

      def keyword_args
        @keyword_args ||= calculate_args(@raw_keyword_args.values)
      end

      private

      def calculate_args(arguments)
        arguments.
          map { |o| o.is_a?(Class) ? o : o.class }.
          select { |k| keep?(k) }
      end

      def keep?(klass)
        files_for(klass).
          select { |f| record?(f) }.length.positive?
      end

      def files_for(klass)
        source_files(klass).
          flatten.
          compact.
          uniq
      end

      def source_files(klass)
        AddedMethods.all_method_sources_for(klass).map(&:first)
      end

      def record?(f)
        Delfos.method_logging.include_any_path_in_logging?(f)
      end
    end
  end
end
