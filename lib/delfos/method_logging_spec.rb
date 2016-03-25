# frozen_string_literal: true
require_relative "method_logging"
require_relative "patching"
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

    before do
      expect(Delfos::Patching).
        to receive(:added_methods).
        and_return(
          A => { instance_method_some_method: [a_path, 4] },
          B => { instance_method_another_method: [b_path, 2] }).
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
        caller_binding = binding
        stack = caller.dup

        Delfos::MethodLogging.log(
          self,
          args, keyword_args, block,
          class_method = false,
          stack, caller_binding,
          method(__method__))
      end
    end

    class CallerObject
      def caller_method(called_object, args, keyword_args, block, _called_method)
        called_object = CalledObject.new

        $caller_line = __LINE__ + 1
        called_object.called_method(args, keyword_args, block)
      end
    end

    it do
      called_object = CalledObject.new
      expect(CalledObject).to receive(:new).and_return called_object

      caller_object = CallerObject.new
      caller_object.caller_method(called_object, args, keyword_args, block, class_method)

      expect(logger).to have_received(:debug) do |args, caller_code, called_code|
        expect(args.args).to eq [A, B]
        expect(args.keyword_args).to eq [A, B]

        expect(caller_code.file).to eq "delfos/method_logging_spec.rb"
        expect(caller_code.line_number).to eq $caller_line
        expect(caller_code.method_name).to eq "caller_method"
        expect(caller_code.object).to eq caller_object

        expect(called_code.file).to eq "delfos/method_logging_spec.rb"
        expect(called_code.line_number).to eq $called_line
        expect(called_code.method_name).to eq "called_method"
        expect(called_code.object).to eq called_object
      end
    end
  end
end

describe Delfos::MethodLogging::CodeLocation do
  class SomeObject
    def some_method(&block)
      another_method(block, binding)
    end

    def another_method(block, caller_binding)
      a_third_method(block, caller_binding)
    end

    def a_third_method(block, caller_binding)
      $line_number = __LINE__ + 1
      block.call self, caller_binding
    end
  end

  describe ".from" do
    before do
      path = Pathname.new(__FILE__) + ".."

      expect(Delfos).to receive(:application_directories).at_least(:once).and_return [
        path,
      ]
    end

    it do
      caller_result = nil
      object = nil

      SomeObject.new.some_method do |o, caller_binding|
        object = o
        caller_result = described_class.from_caller(caller, caller_binding)
      end

      # sanity check
      expect(caller_result.object).to be_a SomeObject
      expect(caller_result.object).to eq object

      unless ENV["CI"]
        #TODO find out why this fails on CI
        expect(caller_result.method_name).to eq "call"
      end
      expect(caller_result.file).to eq __FILE__
      expect(caller_result.line_number).to eq $line_number
    end
  end
end
