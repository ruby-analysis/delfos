# frozen_string_literal: true
require "Forwardable" unless defined? Forwardable

module Delfos
  module Patching
    class MethodCache
      class << self
        extend Forwardable

        def_delegators :instance,
          :all_method_sources_for,
          :added_methods,
          :append,
          :find

        def reset!
          @instance = nil
        end

        def instance
          @instance ||= new
        end
      end

      def initialize
        @added_methods = {}
      end

      attr_reader :added_methods

      def all_method_sources_for(klass)
        fetch(klass).values.map{|s| [s[:file], s[:line_number]] }
      end

      def files_for(klass)
        source_files(klass).
          flatten.
          compact.
          uniq
      end

      def source_files(klass)
        all_method_sources_for(klass).map(&:first)
      end

      def method_source_for(klass, key)
        find(klass, key)
      end

      def append(klass, key, file, line_number)
        m = fetch(klass)[key]

        fetch(klass)[key] = {file: file, line_number: line_number} if m.nil?
      end

      def find(klass, key)
        result = fetch(klass)[key]
        result
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
