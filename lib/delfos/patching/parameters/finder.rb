# frozen_string_literal: true
require "parser/current" unless defined?(Parser::CurrentRuby)

require_relative "determine_constant"
require_relative "argument_rewriter"
require_relative "file_parser_cache"

module Delfos
  module Patching
    module Parameters
      class Finder
        include DetermineConstant

        def initialize(filename)
          @filename = filename
        end

        attr_reader :filename

        def args_from(method, type)
          if method.respond_to?(:receiver) && method.receiver.is_a?(Module)
            args_from_defs(method, type)
          else
            args_from_def(method, type)
          end
        end

        def args_from_defs(method, type)
          sexp = find_defs(method.name)
          return "" unless sexp

          args = case sexp.type
                when :def
                  sexp.children[1]
                when :defs
                  sexp.children[2]
                end

          format_args(args, type, method)
        end

        def find_defs(m, sexp = file_sexp)
          return unless sexp.is_a?(Parser::AST::Node)

          if (sexp.type == :defs) && (node_name(sexp) == m.to_s)
            return sexp
          end

          if sexp.type == :sclass
            result = find_def(m, sexp)
            return result if result
          end

          check_children(m, sexp) do |s|
            find_defs(m, s)
          end
        end

        def args_from_def(method, type)
          sexp = find_def(method.name)
          return "" unless sexp

          args = sexp.children[1]

          format_args(args, type, method)
        end

        def format_args(args, type, method)
          args = args.children.
            select { |a| a.type == type }.
            map(&:children)

          args.each_with_object({}) do |(name, val), result|
            result[name] = rewrite_constants(val, method)
          end
        end

        def find_def(method_name, sexp = file_sexp)
          return unless sexp.is_a?(Parser::AST::Node)

          return sexp if (sexp.type == :def) && (node_name(sexp) == method_name.to_s)

          check_children(method_name, sexp) do |s|
            find_def(method_name, s)
          end
        end

        def check_children(method_name, sexp)
          sexp.children.each do |s|
            next unless s
            result = yield(s)
            return result if result
          end

          nil
        end

        def node_name(sexp)
          snippet_from(sexp.loc.name)
        end

        private

        def methods(sexp, found = [])
          if sexp.type == :def
            found << sexp
            found
          end
        end

        def rewrite_constants(val, method)
          source = val.loc.expression.source

          if contains_constant?(val)
            ArgumentRewriter.new(source, method.owner).perform
          else
            source
          end
        end

        def contains_constant?(expression)
          return true if expression.respond_to?(:type) && expression.type == :const
          return unless expression.respond_to?(:children)

          expression.children.any? do |c|
            contains_constant?(c)
          end
        end

        def snippet_from(o)
          o.source
        end

        def file_sexp
          @file_sexp ||= FileParserCache.for(filename) do
            Parser::CurrentRuby.parse(file_contents)
          end
        end

        def file_contents
          Pathname.new(filename).read
        end
      end
    end
  end
end
