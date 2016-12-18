# frozen_string_literal: true
require "Forwardable" unless defined? Forwardable

module Delfos
  module Patching
    class MethodCache
      class << self
        extend Forwardable

        def_delegators :instance,
          :all_method_sources_for,
          :method_source_for,
          :append,
          :find

        def instance
          @instance ||= new
        end
      end

      def initialize
        @added_methods = {}
      end

      attr_reader :added_methods

      def all_method_sources_for(klass)
        fetch(klass).values.map(&:source_location)
      end

      def method_source_for(klass, key)
        meth = find(klass, key)

        meth&.source_location
      end

      def append(klass, key, original_method)
        m = fetch(klass)[key]

        fetch(klass)[key] = original_method if m.nil?
      end

      def find(klass, key)
        fetch(klass)[key]
      end

      private

      def fetch(klass)
        # Find method definitions defined in klass or its ancestors
        super_klass = klass.ancestors.detect do |k|
          (fetch_without_default(k) || {}).values.length.positive?
        end

        added_methods[(super_klass || klass).to_s] ||= {}
      end

      def fetch_without_default(klass)
        added_methods[klass.to_s]
      end
    end
  end
end
