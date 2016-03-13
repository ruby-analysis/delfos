# frozen_string_literal: true
require_relative "code"
describe Delfos::MethodLogging::Code do
  describe "#file" do
    let(:code) { described_class.new(code_location) }
    let(:code_location) { double "code location", file: filename }
    let(:dir) { "/Users/mark/code/some_app/" }

    before do
      expect(Delfos).to receive(:application_directories).and_return [
        "/Users/mark/code/some_app/app",
        "/Users/mark/code/some_app/lib",
      ]
    end

    context "with a file in one of the defined directories" do
      let(:filename) { "#{dir}app/models/user.rb" }
      it do
        expect(code.file).to eq "app/models/user.rb"
      end
    end

    context "with a file in another directory" do
      let(:filename) { "#{dir}lib/some_file.rb" }

      it do
        expect(code.file).to eq "lib/some_file.rb"
      end
    end

    context "with a file in neither directory" do
      let(:filename) { "/some_big/long/path/lib/any_file.rb" }

      it do
        expect(code.file).to eq "/some_big/long/path/lib/any_file.rb"
      end
    end
  end
end
