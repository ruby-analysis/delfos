require "./fixtures/parameter_extraction"
require_relative "parameter_extraction"

# frozen_string_literal: true
module Delfos
  module Patching
    RSpec.describe ParameterExtraction do
      let(:container) { DelfosSpecs::ParameterExtractionExample.new }
      let(:meth) { container.method(method_name) }
      let(:extraction) { described_class.new(meth) }

      describe "#required_args" do
        let(:method_name) { :with_required_args }

        it do
          expect(extraction.required_args).to eq [:a, :b]
        end
      end
    end
  end
end
