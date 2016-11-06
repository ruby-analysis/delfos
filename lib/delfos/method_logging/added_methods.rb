require "Forwardable" unless defined? Forwardable

module Delfos
  module MethodLogging
    class AddedMethods
      class << self
        extend Forwardable

        def_delegators :instance,
          :method_sources_for,
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

      def method_sources_for(klass)
        fetch(klass).values.map(&:source_location)
      end

      def append(klass, key, original_method)
        fetch(klass)[key] = original_method
      end

      def find(klass, key)
        fetch(klass)[key]
      end

      private

      def fetch(klass)
        # Find method definitions defined in klass or its ancestors
        super_klass = klass.ancestors.detect do |k|
          (fetch_without_default(k) || {}).values.length > 0
        end

        added_methods[(super_klass || klass).to_s] ||= {}
      end

      def fetch_without_default(klass)
        added_methods[klass.to_s]
      end
    end
  end
end
