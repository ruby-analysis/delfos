# frozen_string_literal: true

require_relative "common_path"

module Delfos
  module FileSystem
    module AppDirectories
      extend self

      def exclude_file?(file)
        !include_file?(file)
      end

      def include_file?(file)
        return false if file.nil?
        with_cache(file) { should_include?(file) }
      end

      def reset!
        @cache = nil
      end

      private

      def should_include?(file)
        CommonPath.included_in?(expand_path(file), Delfos.application_directories)
      end

      def expand_path(f)
        Pathname.new(f).expand_path
      end

      def with_cache(key)
        cache.include?(key) ? cache[key] : cache[key] = yield
      end

      def cache
        @cache ||= {}
      end
    end
  end
end
