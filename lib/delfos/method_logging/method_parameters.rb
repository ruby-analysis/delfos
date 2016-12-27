# frozen_string_literal: true
require_relative "../../delfos"
require_relative "../common_path"
require "delfos/patching/method_cache"

module Delfos
  module MethodLogging
    class MethodParameters
      attr_reader :block

      def initialize(args=[], keyword_args=nil, block=nil)
        @raw_args         = args
        @raw_keyword_args = keyword_args
        @block            = block
      end

      def args
        @args ||= calculate_args(@raw_args)
      end

      def argument_classes
        (args + keyword_args).uniq
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
          any? { |f| record?(f) }
      end

      def files_for(klass)
        Patching::MethodCache.files_for(klass)
      end

      def record?(f)
        Delfos::MethodLogging.include_file?(f)
      end
    end
  end
end
