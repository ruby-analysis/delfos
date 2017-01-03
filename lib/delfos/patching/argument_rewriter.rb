unless defined?(Parser::CurrentRuby)
  require "parser/current"
end

require_relative "determine_constant"

module Delfos
  module Patching
    class ArgumentRewriter
      def initialize(code, klass)
        @parser = Parser::CurrentRuby.new

        @code = if code.respond_to? :force_encoding
          code.dup.force_encoding(@parser.default_encoding)
        else
          code
        end

        @klass = klass
      end

      def perform
        rewriter.rewrite(buffer, ast)
      end

      private

      def ast
        @parser.parse(buffer)
      end

      def rewriter
        ParserRewriter.new(@klass)
      end

      def buffer
        @buffer ||= Parser::Source::Buffer.new("(fragment:0)").tap{|b| b.source = @code }
      end
    end

    class ParserRewriter < ::Parser::Rewriter
      include Delfos::Patching::DetermineConstant

      def initialize(klass)
        @klass = klass
        super()
      end

      def on_const(node)
        start, finish = node.loc.expression.begin_pos, node.loc.expression.end_pos
        constant = constant_from(node, @klass)
        replace(range(start, finish), constant)
      end

      private

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

