# frozen_string_literal: true
describe "patching #{BasicObject}" do
  let(:a) { A.new }
  let(:b) { B.new }
  let(:logger) { double "logger", debug: nil }

  before do
    require_relative "../delfos"
    Delfos.logger = logger
    Delfos.application_directories = [
      Pathname.new(File.expand_path(__FILE__)) + "../../../fixtures",
    ]
    Delfos.perform_patching!

    load "./fixtures/a.rb"
    load "./fixtures/b.rb"
  end

  it do
    expect(B).to receive(:new).and_return b
    a.some_method(b, 2, c: b, b: "some string")

    expect(logger).to have_received(:debug) do |args, caller_code, called_code|
      expect(caller_code.object).to eq(a)
      expect(called_code.object).to eq(b)
      expect(args.args).to eq [A, B]
      expect(args.keyword_args).to eq([B])
    end
  end
end
