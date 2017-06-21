# frozen_string_literal: true

require "securerandom"

module Delfos
  module CallStack
    class Stack
      attr_reader :uuid

      def initialize(on_empty: nil)
        @on_empty = on_empty
        @uuid = SecureRandom.uuid
      end

      def push(method_object)
        call_sites.push(method_object)
        self.height += 1

        self.execution_count += self.height == 1 ? 1 : 0
      end

      def pop
        raise PoppingEmptyStackError if self.height.zero?

        self.height -= 1

        return unless height.zero? && call_sites.length.positive?

        @on_empty&.call
        self.call_sites = []
      end

      def pop_until_top!
        pop while self.height.positive?
      end

      def height
        @height ||= 0
      end

      def execution_count
        @execution_count ||= 0
      end

      def call_sites
        @call_sites ||= []
      end

      def step_count
        call_sites.length
      end

      attr_writer :height, :step_count, :execution_count, :call_sites
    end

    class PoppingEmptyStackError < StandardError
    end
  end
end
