# frozen_string_literal: true
require "Forwardable" unless defined? Forwardable

module Delfos
  module Patching
    class MethodCache
      class << self
        extend Forwardable

        def_delegators :instance,
          :files_for,
          :append,
          :find

        def reset!
          @instance = nil
        end

        def instance
          @instance ||= new
        end

        def each_method
          instance.send(:added_methods).each do |klass, methods|
            methods.each do |k, m|
              class_method = !!(k[/^ClassMethod_/])
              yield klass, m, class_method
            end
          end
        end
      end

      def initialize
        @added_methods = {}
      end

      def files_for(klass)
        fetch(klass).
          values.
          map(&:source_location).
          compact.
          map(&:first).
          compact.
          uniq
      end

      def append(klass:, method:)
        class_method = method.respond_to?(:receiver) && method.receiver.is_a?(Module)
        key = key_for(class_method, method.name)
        m = fetch(klass)[key]

        fetch(klass)[key] = method if m.nil?
      end

      def find(klass:, method_name:, class_method:)
        key = key_for(class_method, method_name)

        fetch(klass)[key]
      end

      private

      attr_reader :added_methods

      def key_for(class_method, method_name)
        class_method ? "ClassMethod_#{method_name}" : "InstanceMethod_#{method_name}"
      end

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
