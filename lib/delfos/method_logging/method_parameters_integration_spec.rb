# frozen_string_literal: true
require_relative "method_parameters"
require "./fixtures/b"
require "./fixtures/a"
require "delfos/method_logging"

module Delfos
  module MethodLogging
    describe MethodParameters, "Integration" do
      let(:a) { A.new }
      let(:b) { B.new }
      let(:c) { 1 }
      let(:d) { "" }
      let(:a_path) { File.expand_path "./fixtures/a.rb" }
      let(:b_path) { File.expand_path "./fixtures/b.rb" }

      before do
        path = Pathname.new(File.expand_path(__FILE__)) + "../../../../fixtures"
        Delfos.application_directories = [path]

        Delfos::Patching::MethodCache.append(klass: A, method: A.instance_method("some_method"))
        Delfos::Patching::MethodCache.append(klass: A, method: A.instance_method("to_s"))
        Delfos::Patching::MethodCache.append(klass: B, method: B.instance_method("another_method"))
        Delfos::Patching::MethodCache.append(klass: B, method: B.instance_method("cyclic_dependency"))
      end

      subject { described_class.new([a, b, c, d], c: c, d: d) }

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
