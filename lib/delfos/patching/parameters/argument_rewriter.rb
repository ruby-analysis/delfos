# frozen_string_literal: true
require "parser/current" unless defined?(Parser::CurrentRuby)

require_relative "parser_rewriter"

module Delfos
  module Patching
    module Parameters
      class ArgumentRewriter
        def initialize(code, klass)
          @code = if code.respond_to? :force_encoding
                    code.dup.force_encoding(parser.default_encoding)
                  else
                    code
                  end

          @klass = klass
        end

        def perform
          rewriter.rewrite(buffer, ast)
        end

        private

        def parser
          @parser ||= Parser::CurrentRuby.new
        end

        def ast
          parser.parse(buffer)
        end

        def rewriter
          ParserRewriter.new(@klass)
        end

        def buffer
          @buffer ||= Parser::Source::Buffer.new("(fragment:0)").tap { |b| b.source = @code }
        end
      end
    end
  end
end
