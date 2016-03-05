require_relative "method_logging"

describe Delfos::MethodLogging do
  describe ".log" do
    let(:block) { double "block" }
    let(:class_method) { false }

    let(:stack) do
      [
        "lib/something.rb:1:in `method_a'",
        "lib/another.rb:5:in `method_b'",
        "lib/another.rb:3:in `method_b'",
        "lib/another.rb:2:in `method_b'",
        "lib/yet_another.rb:2:in `method_c'",
      ]
    end

    let(:called_method){ double called_method_name,
                         source_location: [called_source_file  , called_source_line],
                         name: called_method_name}

    let(:called_method_name) { "method_a" }
    let(:called_source_file) { "lib/another.rb" }
    let(:called_source_line) { 5 }

    let(:args) { [double("arg 1", class: "Arg1 Class"), double("arg 2", class: "Arg2 Class")] }
    let(:keyword_args) { {key1: keyword_value_1, key2: class_keyword  } }
    let(:keyword_value_1) { double "keyword value 1", class: "keyword arg 1 class" }
    let(:class_keyword) { double "SomeClass", is_a?: true }


    let(:called_object) { double "called_object" }
    let(:logger) { double "logger", debug: nil }

    before do
      Delfos.logger = logger
      Delfos.application_directories = ["lib"]
    end

    it do
      caller_binding = binding

      Delfos::MethodLogging.log(
        called_object,
        args, keyword_args, block,
        class_method,
        stack, caller_binding,
        called_method)

      expect(logger).to have_received(:debug) do |args, caller_code, called_code|
        expect(args.formatted_args).to eq ["Arg1 Class", "Arg2 Class"]
        expect(args.formatted_keyword_args).to eq ["keyword arg 1 class", class_keyword]

        expect(caller_code.line_number).to eq "1"
        expect(caller_code.file).to eq "lib/something.rb"
        expect(caller_code.method_name).to eq "method_a"
        #expect(caller_code.object).to eq 1

        expect(called_code.line_number).to eq called_source_line
        expect(called_code.file).to eq called_source_file
        expect(called_code.method_name).to eq "method_a"
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

      expect(Delfos).to receive(:application_directories).and_return [
        path
      ]
    end

    it do
      result = nil
      object = nil

      SomeObject.new.some_method do |o, caller_binding|
        object = o
        result = described_class.from(caller, caller_binding, false)
      end

      #sanity check
      expect(result.object).to be_a SomeObject
      expect(result.object).to eq object

      expect(result.method_name).to eq "call"
      expect(result.file).to eq __FILE__
      expect(result.line_number).to eq $line_number.to_s
    end
  end
end

describe Delfos::MethodLogging::Code do
  describe "#file" do
    let(:code) { described_class.new(code_location) }
    let(:code_location) { double "code location", file: filename }
    let(:dir) { "/Users/mark/code/some_app/" }

    before do
      expect(Delfos).to receive(:application_directories).and_return [
        "/Users/mark/code/some_app/app",
        "/Users/mark/code/some_app/lib"
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

