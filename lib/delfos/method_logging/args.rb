# frozen_string_literal: true
require_relative "../../delfos"
require_relative "../common_path"
require_relative "./klass_determination"
require_relative "./added_methods"

module Delfos
  module MethodLogging
    class Args
      include KlassDetermination

      def initialize(args, keyword_args)
        @raw_args = args
        @raw_keyword_args = keyword_args
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
          map { |o| klass_for(o) }.
          select { |k| keep?(k)}
      end

      def keep?(klass)
        files_for(klass).
          select{ |f| record?(f) }.length > 0
      end

      def files_for(klass)
        source_files(klass).
          flatten.
          compact.
          uniq
      end

      def source_files(klass)
        sources = AddedMethods.method_sources_for(klass)

        sources.map(&:first)
      end


      def record?(f)
        Delfos.method_logging.include_any_path_in_logging?(f)
      end
    end
  end
end
