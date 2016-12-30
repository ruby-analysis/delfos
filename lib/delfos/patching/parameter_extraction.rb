# frozen_string_literal: true

require_relative "method_finder"

module Delfos
  module Patching
    class ParameterExtraction
      attr_reader :meth, :finder

      def initialize(meth)
        @meth = meth
        @finder = MethodFinder.new(meth.source_location.first)
      end

      def parameters
        output = []
        output << required_args_string if required_args.length.positive?
        output << optional_args_string if optional_args.length.positive?
        output << rest_args if rest_args.length.positive?
        output << keyword_args_string  if keyword_args.length.positive?
        output << required_keyword_args_string  if required_keyword_args.length.positive?
        output << rest_keyword_args if rest_keyword_args.length.positive?
        output << block_string if block
        output.join(", ")
      end

      def required_args
        select_parameters(:req)
      end

      def required_args_string
        required_args.map(&:to_s).join(", ")
      end

      def optional_args
        finder.args_from(meth, :optarg)
      end

      def optional_args_string
        optional_args.map{|name, value| "#{name}=#{value}" }.join(", ")
      end

      def keyword_args
        finder.args_from(meth, :kwoptarg)
      end

      def keyword_args_string
        keyword_args.map{|k,v| "#{k}: #{v}"}.join(", ")
      end

      def block
        select_parameters(:block).first
      end

      def block_string
        "&#{block}"
      end

      def required_keyword_args
        select_parameters(:keyreq)
      end

      def required_keyword_args_string
        required_keyword_args.map{|k| "#{k}:"}.join(", ")
      end

      def rest_args
        args = select_parameters(:rest).first
        if args
          "*#{args}"
        else
          ""
        end
      end

      def rest_keyword_args
        args = select_parameters(:keyrest).first
        if args
          "**#{args}"
        else
          ""
        end
      end
      private

      def method_parameters
        meth.parameters
      end

      def select_parameters(type)
        method_parameters.select{|t, name| type == t } .map(&:last)
      end
    end
  end
end
