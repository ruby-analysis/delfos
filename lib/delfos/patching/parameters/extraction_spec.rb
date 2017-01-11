# frozen_string_literal: true
require "./fixtures/parameter_extraction"
require_relative "extraction"

# frozen_string_literal: true
module Delfos
  module Patching
    module Parameters
      RSpec.describe Extraction do
        let(:container) { DelfosSpecs::ParameterExtractionExample.new }
        let(:meth) { container.method(method_name) }
        let(:extraction) { described_class.new(meth) }

        describe "#required_args" do
          let(:method_name) { :with_required_args }

          it do
            expect(extraction.required_args).to eq [:a, :b]
          end
        end

        describe "#optional_args" do
          let(:method_name) { :with_optional_args }

          it do
            expect(extraction.optional_args).to eq(a: "nil", b: "2", c: '"some_string"')
          end

          context "with constants defined as defaults" do
            let(:method_name) { :with_optional_args_with_constant_defaults }

            it "fully qualifies the constants" do
              expect(extraction.optional_args).to eq(
                a:  "DelfosSpecs::SomeOtherConstant",
                b: "File",
                c: "DelfosSpecs::ANOTHER_CONSTANT",
                d: 'DelfosSpecs::SomeOtherConstant.new("asdf")',
                e: "DelfosSpecs::SomeOtherConstant.new(DelfosSpecs::ANOTHER_CONSTANT)",
                f: "DelfosSpecs::SomeOtherConstant.new(DelfosSpecs::SomeOtherConstant.new(DelfosSpecs::ANOTHER_CONSTANT))",
              )
            end
          end
        end

        describe "#block" do
          let(:method_name) { :with_block }

          it do
            expect(extraction.block).to eq :some_block
          end
        end

        describe "#keyword_args" do
          let(:method_name) { :with_keyword_args }

          it do
            expect(extraction.keyword_args).
              to eq(asdf: "1", qwer: "{}", some_call: "a_method_call")
          end
        end

        describe "#required_keyword_args" do
          let(:method_name) { :with_required_keyword_args }

          it do
            expect(extraction.required_keyword_args).to eq [:jkl, :iop]
          end
        end

        describe "#rest_args" do
          let(:method_name) { :with_rest_args }

          it do
            expect(extraction.rest_args).to eq :args
          end
        end

        describe "#rest_args_string" do
          let(:method_name) { :with_rest_args }

          it do
            expect(extraction.rest_args_string).to eq "*args"
          end
        end

        describe "#rest_keyword_args" do
          let(:method_name) { :with_rest_keyword_args }

          it do
            expect(extraction.rest_keyword_args).to eq :kw_args
          end
        end

        describe "#rest_keyword_args_string" do
          let(:method_name) { :with_rest_keyword_args }

          it do
            expect(extraction.rest_keyword_args_string).to eq "**kw_args"
          end
        end

        describe "#parameters" do
          context "with required_args" do
            let(:method_name) { :with_required_args }

            it do
              expect(extraction.parameters).to eq "a, b"
            end
          end

          context "with optional_args" do
            let(:method_name) { :with_optional_args }

            it do
              expect(extraction.parameters).to eq("a=nil, b=2, c=\"some_string\"")
            end
          end

          context "with a block" do
            let(:method_name) { :with_block }

            it do
              expect(extraction.parameters).to eq "&some_block"
            end
          end

          context "with keyword_args" do
            let(:method_name) { :with_keyword_args }

            it do
              expect(extraction.parameters).
                to eq("asdf: 1, qwer: {}, some_call: a_method_call")
            end
          end

          context "with required keyword args" do
            let(:method_name) { :with_required_keyword_args }

            it do
              expect(extraction.parameters).to eq "jkl:, iop:"
            end
          end

          context "with optional and required args" do
            let(:method_name) { :with_optional_and_required_args }

            it do
              expect(extraction.parameters).to eq "a, b, c=1, d=2"
            end
          end

          context "with rest args" do
            let(:method_name) { :with_rest_args }

            it do
              expect(extraction.parameters).to eq "*args"
            end
          end

          context "with rest args and keyword_args" do
            let(:method_name) { :with_rest_args_and_keyword_args }

            it do
              expect(extraction.parameters).to eq "*args, **kw_args"
            end
          end

          context "with everything" do
            let(:method_name) { :with_everything }

            it do
              expect(extraction.parameters).to eq "a, b, c=nil, d=1, *args, asdf: 1, qwer: 2, a_constant: DelfosSpecs::SomeOtherConstant, another_constant: DelfosSpecs::ANOTHER_CONSTANT, yuio:, uiop:, **kw_args, &some_block"
            end
          end
        end
      end
    end
  end
end
