# frozen_string_literal: true
require_relative "method_logging"
require_relative "./patching/method_override"
require_relative "../../fixtures/a"
require_relative "../../fixtures/b"

module Delfos
  describe MethodLogging do
    describe ".log" do
      let(:block) { double "block" }
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
        expect_any_instance_of(Patching::MethodCache).
          to receive(:added_methods).
          at_least(:once).
          and_return("A" => { instance_method_some_method: { file: a_path, line_number: 4 } },
                     "B" => { instance_method_another_method: { file: b_path, line_number: 2 } })

        Delfos.call_site_logger = call_site_logger
        path_fixtures = Pathname.new(File.expand_path(__FILE__)) + "../../../fixtures"
        path_spec     = Pathname.new(File.expand_path(__FILE__)) + ".."
        Delfos.application_directories = [path_spec, path_fixtures]
      end

      class DummyPatchedObject
        # This represents the stack offset from the point at parsing the stack,
        # and the aimed at location to determine the caller object. It is
        # unfortunately implementation specific. Hence the magic number.
        MAGIC_OFFSET = 3

        # This method represents a simulated version of a method patched by
        # MethodOverride#setup
        def called_method(args, keyword_args, block)
          $called_line = __LINE__ - 1
          call_site = MethodLogging::CallSiteParsing.new(caller.dup, binding.dup, stack_offset: MAGIC_OFFSET).perform
          args = Patching::MethodArguments.new(args, keyword_args, block, should_wrap_exception = true)

          Delfos::MethodLogging.log(
            call_site,
            self,
            method(__method__),
            class_method = false,
            args,
          )

          # real method would do stuff here
        end
      end

      class TestCallSiteObject
        def call_site_method(called_object, args, keyword_args, block)
          $call_site_line = __LINE__ + 1
          called_object.called_method(args, keyword_args, block)
        end
      end

      it do
        dummy = DummyPatchedObject.new

        call_site_object = TestCallSiteObject.new
        call_site_object.call_site_method(dummy, args, keyword_args, block)

        expect(call_site_logger).to have_received(:log) do |args, call_site, called_code|
          expect(args.args).to eq [A, B]
          expect(args.keyword_args).to eq [A, B]

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

    class SomeObject
      def some_method(&block)
        another_method(block, binding)
      end

      def another_method(block, call_site_binding)
        a_third_method(block, call_site_binding)
      end

      def a_third_method(block, call_site_binding)
        $line_number = __LINE__ + 1
        block.call self, call_site_binding
      end
    end

    describe ".log" do
      before do
        path = Pathname.new(__FILE__) + ".."

        expect(Delfos).to receive(:application_directories).at_least(:once).and_return [
          path,
        ]
      end

      it do
        call_site_result = nil
        object = nil

        SomeObject.new.some_method do |o, call_site_binding|
          object = o
          call_site_result = MethodLogging::CodeLocation.from_call_site(caller, call_site_binding)
        end

        # sanity check
        expect(call_site_result.object).to be_a SomeObject
        expect(call_site_result.object).to eq object

        expect(call_site_result.method_name).to eq "a_third_method"

        expect(call_site_result.file).to eq "delfos/method_logging_spec.rb"
        expect(call_site_result.line_number).to eq $line_number
      end
    end
  end
end
