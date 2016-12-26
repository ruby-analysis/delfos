# frozen_string_literal: true
require "spec_helper"
require_relative "method_arguments"

module Delfos
  module Patching
    describe MethodArguments do
      let(:block) { nil }
      let(:keyword_args) { {} }
      let(:args) { [] }
      let(:should_wrap_exception) { true }
      let(:instance) { described_class.new(args, keyword_args, block, should_wrap_exception) }

      class Bomb < StandardError
      end

      describe "#apply_to" do
        context "with exception wrapping disabled" do
          let(:should_wrap_exception) { false }
          let(:bomb) { -> { raise Bomb } }

          it do
            expect(-> { instance.apply_to(bomb) }).to raise_error Bomb
          end
        end
        context "with exception wrapping enabled" do
          let(:should_wrap_exception) { true }
          let(:bomb) { -> { raise "boom" } }

          it do
            expect(lambda do
              instance.apply_to(bomb)
            end).to raise_error MethodCallingException
          end
        end
      end
    end
  end
end
