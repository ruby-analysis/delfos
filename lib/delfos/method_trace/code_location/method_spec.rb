# frozen_string_literal: true

require_relative "method"

module Delfos
  module MethodTrace
    module CodeLocation
      RSpec.describe Method do
        describe "#file" do
          let(:code_location) do
            described_class.new(object: anything,
                                method_name: anything,
                                class_method: anything,
                                file: filename,
                                line_number: (1..1000).to_a.sample)
          end
          let(:dir) { "/Users/mark/code/some_app" }

          before do
            config = double "config"

            expect(config).to receive(:included_directories).and_return([
                                                                          "/Users/mark/code/some_app/app",
                                                                          "/Users/mark/code/some_app/lib",
                                                                        ])

            allow(Delfos).to receive(:config).and_return config
          end

          context "with a file in one of the defined directories" do
            let(:filename) { "#{dir}/app/models/user.rb" }

            it do
              expect(code_location.file).to eq "app/models/user.rb"
            end
          end

          context "with a file in another directory" do
            let(:filename) { "#{dir}/lib/some_file.rb" }

            it do
              expect(code_location.file).to eq "lib/some_file.rb"
            end
          end

          context "with a file in neither directory" do
            let(:filename) { "/some_big/long/path/lib/any_file.rb" }

            it do
              expect(code_location.file).to eq filename
            end
          end
        end
      end
    end
  end
end
