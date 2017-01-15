# frozen_string_literal: true
module Delfos
  module Patching
    module Parameters
      class ParserRewriter < ::Parser::Rewriter
        def initialize(klass)
          @klass = klass
          super()
        end

        def on_const(node)
          start = node.loc.expression.begin_pos
          finish = node.loc.expression.end_pos
          constant = constant_name_from(node, @klass)
          replace(range(start, finish), constant)
        end

        private

        def constant_name_from(val, klass)
          constant_name = val.to_a.last

          klass = klass_for(klass)

          namespace = namespace_for(klass)

          constant = namespace.const_get(constant_name)

          if constant.is_a?(Module)
            constant.name
          else
            "#{namespace}::#{constant_name}"
          end
        end

        def namespace_for(klass)
          klass_namespaces = klass.name.split("::")
          namespace = klass_namespaces.shift(klass_namespaces.length - 1).join("::")

          Object.const_get namespace
        end

        def klass_for(klass)
          if klass.singleton_class?
            Object.const_get klass.inspect.gsub(/#<Class:|>/, "")
          else
            klass
          end
        end

        def klass_namespace
          @klass.name.split("::")
        end

        def range(start, finish)
          Parser::Source::Range.new(buffer, start, finish)
        end

        def buffer
          @source_rewriter.source_buffer
        end
      end
    end
  end
end
