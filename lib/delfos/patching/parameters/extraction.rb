# frozen_string_literal: true

require_relative "finder"

module Delfos
  module Patching
    module Parameters
      class Extraction
        attr_reader :meth, :finder

        def initialize(meth)
          @meth = meth
          @finder = Finder.new(meth.source_location.first)
        end

        def parameters
          output = []

          [:required_args, :optional_args, :rest_args,
           :keyword_args, :required_keyword_args, :rest_keyword_args,
           :block].each do |a|
             append_if_present(output, a)
           end
          output.join(", ")
        end

        def append_if_present(output, arg)
          output << send("#{arg}_string") if send(arg) && send(arg).length.positive?
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
          optional_args.map { |name, value| "#{name}=#{value}" }.join(", ")
        end

        def keyword_args
          finder.args_from(meth, :kwoptarg)
        end

        def keyword_args_string
          keyword_args.map { |k, v| "#{k}: #{v}" }.join(", ")
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
          required_keyword_args.map { |k| "#{k}:" }.join(", ")
        end

        def rest_args
          select_parameters(:rest).first
        end

        def rest_args_string
          rest_args ? "*#{rest_args}" : ""
        end

        def rest_keyword_args
          select_parameters(:keyrest).first
        end

        def rest_keyword_args_string
          rest_keyword_args ? "**#{rest_keyword_args}" : ""
        end

        private

        def method_parameters
          meth.parameters
        end

        def select_parameters(type)
          method_parameters.select { |t, _name| type == t } .map(&:last)
        end
      end
    end
  end
end
