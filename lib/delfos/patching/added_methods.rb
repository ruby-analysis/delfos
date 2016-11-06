require "Forwardable" unless defined? Forwardable
module Delfos
  class Patching # TODO: make this a module and rename the Patching class
    class AddedMethods
      class << self
        extend Forwardable

        def_delegators :instance,
          :method_sources_for,
          :append,
          :set_sub_klass,
          :fetch_class_method,
          :fetch,
          :method_sources,
          :method_definition_for, :added?

        def instance
          @instance ||= new
        end
      end

      def initialize
        @added_methods = {}
      end

      attr_reader :added_methods

      def fetch(key)
        added_methods[key]
      end

      def method_sources(klass)
        methods = fetch(klass.to_s)
        return [] unless methods

        methods.values.map(&:source_location)
      end

      def method_sources_for(klass)
        (added_methods[klass.to_s] || {}).values.map(&:source_location).map(&:first)
      end

      def set_sub_klass(klass, sub_klass)
        klass_key, sub_klass_key = klass.to_s, sub_klass.to_s

        return unless added_methods[klass_key]

        for_klass(sub_klass_key)

        for_klass(klass_key).each do |k, m|
          if k.match(/^ClassMethod_/)
            unbound = added_methods[klass_key][k].unbind
            bound = unbound.bind(sub_klass)

            added_methods[sub_klass_key][k] = bound
          end
        end
      end

      def method_definition_for(klass, key)
        # Find method definitions defined in klass or its ancestors
        super_klass = klass.ancestors.detect do |k|
          added_methods[k.to_s]
        end

        klass_hash = for_klass(super_klass)
        method_definition = klass_hash[key]
        return unless method_definition
        method_definition.source_location
      end

      def append(klass, key, original_method)
        for_klass(klass)[key] = original_method
      end

      def added?(klass, key)
        return false unless added_methods[klass]
        return false unless for_klass(klass)[key]

        added_methods[klass][key]
      end

      def fetch_class_method(original_method, klass)
        klass_methods = for_klass(klass)
        return original_method unless klass_methods # occurs during class evaluation before Class.inherited callback is called

        method = klass_methods["ClassMethod_#{original_method.name}"]
        method
      end

      private

      def for_klass_and_key(klass, key)
        for_klass(klass)[key]
      end

      def for_klass(klass)
        added_methods[klass.to_s] ||= {}
        added_methods[klass.to_s]
      end
    end
  end
end
