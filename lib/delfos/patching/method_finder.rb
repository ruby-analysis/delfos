unless defined?(Parser::CurrentRuby)
  require "parser/current"
end

require_relative "determine_constant"
require_relative "argument_rewriter"

module Delfos
  module Patching
    class MethodFinder
      include DetermineConstant

      def initialize(filename)
        @filename = filename
      end

      attr_reader :filename

      def args_from(method, type)
        sexp = find(method.name)
        return "" unless sexp

        args = sexp.children[1]

        args = args.children.
          select{|a| a.type == type}.
          map(&:children)

        args.each_with_object({}) do |(name, val), result|
          result[name]= rewrite_constants(val, method)
        end
      end


      def find(m, sexp=file_sexp)
        return unless sexp.is_a?(Parser::AST::Node)

        if (sexp.type == :def) && (node_name(sexp) == m.to_s)
          return sexp
        end

        sexp.children.each do |s|
          next unless s
          result = find(m, s)
          return result if result
        end

        nil
      end

      def node_name(sexp)
        snippet_from(sexp.loc.name)
      end

      private

      def methods(sexp, found=[])
        if sexp.type == :def
          found << sexp
          return found
        end
      end

      def rewrite_constants(val, method)
        ArgumentRewriter.new(snippet_from(val.loc.expression), method.owner).perform
      end

      def snippet_from(o)
        start, finish= o.begin_pos, o.end_pos

        snippet(start, finish)
      end

      def snippet(start, finish)
        file_contents[start.. finish - 1]
      end

      def file_contents
        @file_contents ||= File.read(filename)
      end

      def file_sexp
        Parser::CurrentRuby.parse(file_contents)
      end
    end
  end
end
