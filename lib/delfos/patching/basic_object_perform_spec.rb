# frozen_string_literal: true
describe "patching BasicObject" do
  let(:logger) { double "logger", debug: nil }

  before do
    require_relative "../../delfos"
    Delfos.logger = logger
    Delfos.application_directories = [
      Pathname.new(File.expand_path(__FILE__)) + "../../../../fixtures",
    ]

    Delfos.perform_patching!
  end

  context do
    let(:a) { A.new }
    let(:b) { B.new }

    before do
      load "./fixtures/a.rb"
      load "./fixtures/b.rb"
    end

    it do
      expect(B).to receive(:new).and_return(b).at_least(:once)

      expect(logger).to receive(:debug) do |args, call_site, called_code|
        expect(call_site.object).to eq(a)
        expect(called_code.object).to eq(b)
        expect(args.args).to eq [A, B]
        expect(args.keyword_args).to eq([B])
      end.at_least(:once)

      a.some_method(b, 2, c: b, b: "some string")
    end
  end
end
