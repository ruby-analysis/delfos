# frozen_string_literal: true

require_relative "eval_in_caller"

module Delfos
  module MethodTrace
    module CodeLocation
      class ContainerMethodFactory
        include EvalInCaller
        STACK_OFFSET = 11

        def self.create
          new.create
        end

        def create
          # ensure evaluated and memoised with correct stack offset
          class_method

          CodeLocation.new_method(
            object:       object,
            method_name:  meth,
            file:         file,
            line_number:  line,
            class_method: class_method,
          )
        end

        private

        def object
          @object ||= eval_in_caller("self", STACK_OFFSET)
        end

        def class_method
          # TODO: This is nuts - see issue #16 - https://github.com/ruby-analysis/delfos/issues/16
          #
          # Evaluating "self.is_a?(Module)" is non-deterministic even though it's memoized
          #
          # Somehow in hell the following gives us a workaround
          #
          # You can try it out yourself with `puts class_method` when running
          #
          # spec/integration/neo4j/call_sites_spec.rb
          # vs `puts code_location.inspect` on line 22 of this file
          #
          # and using this more sane implementation:
          #
          # @class_method ||= eval_in_caller('is_a?(Module)', STACK_OFFSET)
          #
          # The output value will be false the first time
          # but true inside the code_location
          @result ||= eval_in_caller("{self =>  is_a?(Module)}", STACK_OFFSET)
          @class_method ||= @result.values.first
        end

        RUBY_IS_MAIN                = "self.class == Object && self&.to_s == 'main'"
        RUBY_SOURCE_LOCATION        = "(__method__).source_location if __method__"
        RUBY_CLASS_METHOD_SOURCE    = "method#{RUBY_SOURCE_LOCATION}"
        RUBY_INSTANCE_METHOD_SOURCE = "self.class.instance_method#{RUBY_SOURCE_LOCATION}"

        def method_finder
          @method_finder ||= class_method ? RUBY_CLASS_METHOD_SOURCE : RUBY_INSTANCE_METHOD_SOURCE
        end

        def file
          @file ||= eval_in_caller("(#{RUBY_IS_MAIN}) ? __FILE__ : ((#{method_finder})&.first)", STACK_OFFSET)
        end

        def line
          @line ||= eval_in_caller("(#{RUBY_IS_MAIN}) ? 0 : ((#{method_finder})&.last)", STACK_OFFSET)
        end

        def meth
          @meth ||= eval_in_caller("__method__", STACK_OFFSET)
        end
      end
    end
  end
end
