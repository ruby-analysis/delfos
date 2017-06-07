# frozen_string_literal: true
require_relative "method_logging"
require_relative "../../fixtures/a"
require_relative "../../fixtures/b"

module Delfos
  describe MethodLogging do
    describe ".log" do
      let(:block) { proc {} }
      let(:class_method) { false }

      let(:args) { [A.new, B.new] }
      let(:keyword_args) { { key1: keyword_value_1, key2: class_keyword } }
      let(:keyword_value_1) { A.new }
      let(:class_keyword) { B }

      let(:called_object) { double "called_object" }
      let(:call_site_logger) { double "call_site_logger", log: nil }

      let(:a_path) { File.expand_path "./fixtures/a.rb" }
      let(:b_path) { File.expand_path "./fixtures/b.rb" }
      let(:method_a) { double "method a", source_location: [a_path, 4] }
      let(:method_b) { double "method b", source_location: [b_path, 2] }

      before do
        Delfos.call_site_logger = call_site_logger
        path_fixtures = Pathname.new(File.expand_path(__FILE__)) + "../../../fixtures"
        path_spec     = Pathname.new(File.expand_path(__FILE__)) + ".."
        Delfos.application_directories = [path_spec, path_fixtures]
      end

      class DummyPatchedObject
        # This represents the stack offset from the point at parsing the stack,
        # and the aimed at location to determine the caller object. It is
        # unfortunately implementation specific. Hence the magic number.
        MAGIC_OFFSET = 4

        # This method represents a simulated version of a method patched by
        # MethodOverride#setup
        def called_method(args, keyword_args, &block)
          $called_line = __LINE__ - 1
          Delfos::MethodLogging.log(
            call_site,
            self,
            method(__method__),
            class_method = false,
          )

          # real method would do stuff here
        end
      end

      class TestCallSiteObject
        def call_site_method(called_object, args, keyword_args, &block)
          $call_site_line = __LINE__ + 1
          called_object.called_method(args, keyword_args, &block)
        end
      end

      it do
        dummy = DummyPatchedObject.new

        call_site_object = TestCallSiteObject.new
        call_site_object.call_site_method(dummy, args, keyword_args, &block)

        expect(call_site_logger).to have_received(:log) do |call_site, called_code|
          expect(call_site.file).to eq "delfos/method_logging_spec.rb"
          expect(call_site.line_number).to eq $call_site_line
          expect(call_site.method_name).to eq "call_site_method"
          expect(call_site.object).to eq call_site_object

          expect(called_code.file).to eq "delfos/method_logging_spec.rb"
          expect(called_code.line_number).to eq $called_line
          expect(called_code.method_name).to eq "called_method"
          expect(called_code.object).to eq dummy
        end
      end
    end
  end
end
