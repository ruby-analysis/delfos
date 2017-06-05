# frozen_string_literal: true
require "pathname"

module Delfos
  describe "patching BasicObject" do
    let(:call_site_logger) { double "call_site_logger" }

    before do
      require "delfos/call_stack"
      allow(Delfos::CallStack).to receive(:push)
      allow(Delfos::CallStack).to receive(:pop)

      Delfos.call_site_logger = call_site_logger
      current_file = Pathname.new(File.expand_path(__FILE__))

      Delfos.application_directories = [
        current_file + "../../../../fixtures",
      ]

      load "delfos/patching/basic_object.rb"
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

        allow(call_site_logger).to receive(:log)

        expect(call_site_logger).to receive(:log) do |call_site, called_code|
          expect(call_site.object).   to eq(a)
          expect(called_code.object). to eq(b)
        end

        a.some_method(b, 2, c: b, b: "some string")
      end
    end
  end
end
