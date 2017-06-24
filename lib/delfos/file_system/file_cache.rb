# frozen_string_literal: true

module Delfos
  module FileSystem
    module FileCache
      def reset!
        @cache = nil
      end

      private

      def with_cache(key)
        cache.include?(key) ? cache[key] : cache[key] = yield
      end

      def cache
        @cache ||= {}
      end
    end
  end
end
