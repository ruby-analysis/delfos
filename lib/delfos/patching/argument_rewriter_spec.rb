require_relative "argument_rewriter"
module Delfos
  module Patching
    RSpec.describe ArgumentRewriter do
      before do
        load "fixtures/argument_rewriter_example.rb"
      end

      let(:input_code) { "WithoutNamespace.new(AnotherWithoutNamespace.new)" }
      let(:klass) { DelfosSpecs::CallingClass }

      it do
        output = described_class.new(input_code, klass).perform
        expect(output).to eq "DelfosSpecs::WithoutNamespace.new(DelfosSpecs::AnotherWithoutNamespace.new)"
      end
    end
  end
end

