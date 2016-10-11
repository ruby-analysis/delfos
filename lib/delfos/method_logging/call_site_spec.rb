# frozen_string_literal: true
require_relative "call_site"

describe Delfos::MethodLogging::CallSite do
  describe "#file" do
    let(:call_site) { described_class.new(anything, anything, anything, filename, (1..1000).to_a.sample) }
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
        expect(call_site.file).to eq "app/models/user.rb"
      end
    end

    context "with a file in another directory" do
      let(:filename) { "#{dir}lib/some_file.rb" }

      it do
        expect(call_site.file).to eq "lib/some_file.rb"
      end
    end

    context "with a file in neither directory" do
      let(:filename) { "/some_big/long/path/lib/any_file.rb" }

      it do
        expect(call_site.file).to eq "/some_big/long/path/lib/any_file.rb"
      end
    end
  end
end
