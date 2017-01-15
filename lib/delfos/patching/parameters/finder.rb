# frozen_string_literal: true
require "parser/current" unless defined?(Parser::CurrentRuby)

require_relative "argument_rewriter"
require_relative "file_parser_cache"

module Delfos
  module Patching
    module Parameters
      class Finder
        def initialize(filename)
          @filename = filename
        end

        attr_reader :filename

        def args_from(method, arg_type)
          sexp = send(def_type_for(method), method.name)
          return "" unless sexp

          index = sexp.type == :def ? 1 : 2
          args = sexp.children[index]

          format_args(args, arg_type, method)
        end

        def def_type_for(method)
          if method.respond_to?(:receiver) && method.receiver.is_a?(Module)
            :find_defs
          else
            :find_def
          end
        end

        def find_defs(m, sexp = file_sexp)
          check_for_def_type(m, sexp, :defs) ||
            check_class_extend_self_definitions(m, sexp) ||
            check_children(m, sexp, :find_defs)
        end

        def find_def(method_name, sexp = file_sexp)
          check_for_def_type(method_name, sexp, :def) ||
            check_children(method_name, sexp, :find_def)
        end

        def check_for_def_type(method_name, sexp, def_type)
          return unless sexp.is_a?(Parser::AST::Node)

          if (sexp.type == def_type) && (sexp.loc.name.source == method_name.to_s)
            return sexp
          end
        end

        def check_class_extend_self_definitions(m, sexp)
          return unless sexp.respond_to?(:type) && sexp.type == :sclass

          find_def(m, sexp)
        end

        def format_args(args, type, method)
          args = args.children.
                 select { |a| a.type == type }.
                 map(&:children)

          args.each_with_object({}) do |(name, val), result|
            result[name] = rewrite_constants(val, method)
          end
        end

        def check_children(method_name, sexp, type)
          return unless sexp.respond_to?(:children)

          sexp.children.each do |s|
            next unless s
            result = send(type, method_name, s)
            return result if result
          end

          nil
        end

        private

        def rewrite_constants(val, method)
          source = val.loc.expression.source

          return source unless contains_constant?(val)

          ArgumentRewriter.new(source, method.owner).perform
        end

        def contains_constant?(expression)
          return true if expression.respond_to?(:type) && expression.type == :const
          return unless expression.respond_to?(:children)

          expression.children.any? do |c|
            contains_constant?(c)
          end
        end

        def file_sexp
          @file_sexp ||= FileParserCache.for(filename) do
            file_contents = Pathname.new(filename).read
            Parser::CurrentRuby.parse(file_contents)
          end
        end
      end
    end
  end
end
