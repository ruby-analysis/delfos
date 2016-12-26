# frozen_string_literal: true
require_relative "args"
require "./fixtures/b"
require "./fixtures/a"
require "delfos/method_logging"

module Delfos
  module MethodLogging
    describe Args, "Integration" do
      let(:a) { A.new }
      let(:b) { B.new }
      let(:c) { 1 }
      let(:d) { "" }
      let(:a_path) { File.expand_path "./fixtures/a.rb" }
      let(:b_path) { File.expand_path "./fixtures/b.rb" }

      def f(*args, **keyword_args)
        double("Arguments object", args: args, keyword_args: keyword_args, block: nil)
      end

      before do
        path = Pathname.new(File.expand_path(__FILE__)) + "../../../../fixtures"
        Delfos.application_directories = [path]
        Delfos::Patching::MethodCache.append(A, "some_method", a_path, 1)
        Delfos::Patching::MethodCache.append(A, "some_other_method", a_path, 2)
        Delfos::Patching::MethodCache.append(B, "another_method", b_path, 3)
        Delfos::Patching::MethodCache.append(B, "yet_another_method", b_path, 15)
      end

      subject { described_class.new(f(a, b, c, d, c: c, d: d)) }

      describe "#args" do
        it do
          expect(subject.args).to eq [A, B]
        end
      end

      describe "#keyword_args" do
        it "ignores non application defined classes" do
          expect(subject.keyword_args).to eq []
        end
      end
    end
  end
end
