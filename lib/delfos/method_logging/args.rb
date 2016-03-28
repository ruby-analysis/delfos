# frozen_string_literal: true
require_relative "../../delfos"
require_relative "../common_path"
require_relative "klass_determination"

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

      def calculate_args(args)
        klass_file_locations(args).select do |_klass, locations|
          Delfos::MethodLogging.include_any_path_in_logging?(locations)
        end.map(&:first)
      end

      def keyword_args
        @keyword_args ||= calculate_args(@raw_keyword_args.values)
      end

      def klass_locations(klass)
        files = method_sources(klass)

        files.flatten.compact.uniq
      end

      private

      def klass_file_locations(args)
        klasses(args).each_with_object({}) { |k, result| result[k] = klass_locations(k) }
      end

      def klasses(args)
        args.map do |k|
          klass_for(k)
        end
      end

      def method_sources(klass)
        (Delfos::Patching.added_methods[klass.to_s] || {}).values.map(&:first)
      end
    end
  end
end
