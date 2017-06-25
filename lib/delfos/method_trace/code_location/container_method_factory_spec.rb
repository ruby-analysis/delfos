# frozen_string_literal: true

require_relative "container_method_factory"

module Delfos
  module MethodTrace
    module CodeLocation
      RSpec.describe ContainerMethodFactory do
        describe ".create" do
          before do
            Delfos.configure { |c| c.application_directories = [Pathname.new("fixtures")] }
            require "./fixtures/container_method_factory/usage.rb"
          end

          context do
            let(:result) { DelfosSpecs::NORMAL_CLASS_TEST_RESULT }

            it "instantiates a code location" do
              expect(result)             .to be_a CodeLocation::Method
              expect(result.object)      .to eq   DelfosSpecs::SomeClass
              expect(result.method_name) .to eq   "container_method"
              expect(result.method_type) .to eq   "ClassMethod"
              expect(result.line_number) .to eq   DelfosSpecs::SomeClass::LINE_DEFINITION_RESULT
              expect(result.file)        .to eq   "fixtures/container_method_factory/usage.rb"
              expect(result.method_object) .to eq DelfosSpecs::SomeClass.method(:container_method)
              expect(result.super_method)  .to eq nil
            end
          end

          context do
            let(:result) { DelfosSpecs::SUB_CLASS_TEST_RESULT }

            it "returns the super_method when the call site is inside the super method" do
              expect(result)               .to be_a CodeLocation::Method
              expect(result.object)        .to eq   DelfosSpecs::SubClass
              expect(result.method_name)   .to eq   "container_method"
              expect(result.method_type)   .to eq   "ClassMethod"
              expect(result.file)          .to eq   "fixtures/container_method_factory/usage.rb"
              expect(result.line_number)   .to eq   DelfosSpecs::SubClass::LINE_DEFINITION_RESULT
              expect(result.method_object) .to eq   DelfosSpecs::SubClass.method(:container_method)
              expect(result.super_method)  .to eq   DelfosSpecs::SubClass.method(:container_method).super_method
            end
          end
        end
      end
    end
  end
end
