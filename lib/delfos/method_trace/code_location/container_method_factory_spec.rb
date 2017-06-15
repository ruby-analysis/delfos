# frozen_string_literal: true

require_relative "container_method_factory"

module Delfos
  module MethodTrace
    module CodeLocation
      RSpec.describe ContainerMethodFactory do
        describe ".create" do
          it "instantiates a code location" do
            Delfos.application_directories = [Pathname.new("fixtures")]
            require "./fixtures/container_method_factory_usage.rb"

            expect(CONTAINER_METHOD_CONSTANT).to be_a CodeLocation::Method
            expect(CONTAINER_METHOD_CONSTANT.method_name).to eq  "container_method"
            expect(CONTAINER_METHOD_CONSTANT.line_number).to eq 8
            expect(CONTAINER_METHOD_CONSTANT.file).to eq "fixtures/container_method_factory_usage.rb"
          end
        end
      end
    end
  end
end
