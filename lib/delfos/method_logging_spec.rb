# frozen_string_literal: true
require_relative "method_logging"
require_relative "patching/patching"
require_relative "../../fixtures/a"
require_relative "../../fixtures/b"

describe Delfos::MethodLogging do
  describe ".log" do
    let(:block) { double "block" }
    let(:class_method) { false }

    let(:args) { [A.new, B.new] }
    let(:keyword_args) { { key1: keyword_value_1, key2: class_keyword } }
    let(:keyword_value_1) { A.new }
    let(:class_keyword) { B }

    let(:called_object) { double "called_object" }
    let(:logger) { double "logger", debug: nil }

    let(:a_path) { File.expand_path "./fixtures/a.rb" }
    let(:b_path) { File.expand_path "./fixtures/b.rb" }
    let(:method_a) { double "method a", source_location: [a_path, 4] }
    let(:method_b) { double "method b", source_location: [b_path, 2] }

    before do
      expect(Delfos::Patching).
        to receive(:added_methods).
        and_return(
          "A" => { instance_method_some_method:  method_a},
          "B" => { instance_method_another_method: method_b }).
        at_least(:once)

      Delfos.logger = logger
      path_fixtures = Pathname.new(File.expand_path(__FILE__)) + "../../../fixtures"
      path_spec     = Pathname.new(File.expand_path(__FILE__)) + ".."
      Delfos.application_directories = [path_spec, path_fixtures]
    end

    class CalledObject
      # This method represents a method with the meta programming hooks added for the logging
      def called_method(args, keyword_args, block)
        $called_line = __LINE__ - 1
        call_site_binding = binding
        stack = caller.dup

        Delfos::MethodLogging.log(
          self,
          args, keyword_args, block,
          class_method = false,
          stack, call_site_binding,
          method(__method__))
      end
    end

    class CallSiteObject
      def call_site_method(called_object, args, keyword_args, block, _called_method)
        called_object = CalledObject.new

        $call_site_line = __LINE__ + 1
        called_object.called_method(args, keyword_args, block)
      end
    end

    it do
      called_object = CalledObject.new
      expect(CalledObject).to receive(:new).and_return called_object

      call_site_object = CallSiteObject.new
      call_site_object.call_site_method(called_object, args, keyword_args, block, class_method)

      expect(logger).to have_received(:debug) do |args, call_site, called_code|
        expect(args.args).to eq [A, B]
        expect(args.keyword_args).to eq [A, B]

        expect(call_site.file).to eq "delfos/method_logging_spec.rb"
        expect(call_site.line_number).to eq $call_site_line
        expect(call_site.method_name).to eq "call_site_method"
        expect(call_site.object).to eq call_site_object

        expect(called_code.file).to eq "delfos/method_logging_spec.rb"
        expect(called_code.line_number).to eq $called_line
        expect(called_code.method_name).to eq "called_method"
        expect(called_code.object).to eq called_object
      end
    end
  end
end

describe Delfos::MethodLogging do
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
        call_site_result = Delfos::MethodLogging::CallSite.from(caller, call_site_binding)
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
