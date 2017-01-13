# frozen_string_literal: true

require "./fixtures/parameter_extraction"
require_relative "finder"

module Delfos
  module Patching
    module Parameters
      RSpec.describe Finder do
        let(:container) { DelfosSpecs::ParameterExtractionExample.new }
        let(:meth) { container.method(method_name) }
        let(:finder) { described_class.new("./fixtures/parameter_extraction.rb") }
        subject { finder.args_from(meth, arg_type) }

        describe "#args_from" do
          let(:meth) { container.method(method_name) }

          context "wth a class method" do
            subject { finder.args_from(meth, arg_type) }
            let(:arg_type) { :optarg }
            let(:method_name) { :a_class_method }
            let(:container) { DelfosSpecs::ParameterExtractionExample }

            it do
              expect(subject).to eq(source_requirements: "{}",
                                    base: "[]", 
                                    gem_version_promoter: 'DelfosSpecs::SomeOtherConstant.new',
                                    additional_base_requirements: "[]"
                                   )
            end
          end
          context "wth a self << class style method" do
            subject { finder.args_from(meth, arg_type) }
            let(:arg_type) { :optarg }
            let(:method_name) { :another_class_method }
            let(:container) { DelfosSpecs::ParameterExtractionExample }

            it do
              finder.args_from(meth, arg_type)

              expect(subject).to eq(source_requirements: "{}",
                                    base: "[]", 
                                    gem_version_promoter: 'DelfosSpecs::SomeOtherConstant.new',
                                    additional_base_requirements: "[]"
                                   )
            end
          end

          context "with optional arguments" do
            let(:arg_type) { :optarg }
            let(:method_name) { :with_optional_args }

            it do
              expect(subject).to eq(a: "nil", b: "2", c: '"some_string"')
            end

            context "with constants defined as defaults" do
              let(:method_name) { :with_optional_args_with_constant_defaults }

              it "fully qualifies the constants" do
                expect(subject).to eq(
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
        end

        describe "#keyword_args" do
          let(:arg_type) { :kwoptarg }
          let(:method_name) { :with_keyword_args }

          it do
            expect(subject).
              to eq(asdf: "1", qwer: "{}", some_call: "a_method_call")
          end
        end
      end
    end
  end
end
