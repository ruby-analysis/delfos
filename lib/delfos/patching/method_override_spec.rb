# frozen_string_literal: true
require_relative "method_override"
require_relative "unstubbing_spec_helper"

# HACK: this is awful
Delfos::Patching::MethodOverride.extend  Delfos::Patching::Unstubbing::ClassMethods
Delfos::Patching::MethodOverride.prepend Delfos::Patching::Unstubbing::InstanceMethods

describe Delfos::Patching::MethodOverride do
  class SomeRandomClass
    $class_method_line_number = __LINE__ + 1
    def self.some_class_method
    end

    def some_externally_called_public_method
      some_public_method
    end

    $instance_method_line_number = __LINE__ + 1
    def some_public_method
      some_private_method
    end

    private

    def some_private_method
      "private"
    end
  end

  let(:klass) { SomeRandomClass }
  let(:some_random_instance) { klass.new }

  before do
    stub_const("Delfos::CallStack", double("CallStack class"))

    allow(Delfos::MethodLogging).to receive(:exclude?) do
      klass != SomeRandomClass
    end

    allow(Delfos::MethodLogging).to receive(:log)
    allow(Delfos::CallStack).to receive(:pop)
    allow(Delfos::CallStack).to receive(:push)
  end

  after(:each) do
    described_class.unstub_all!
  end

  describe ".added_methods" do
    let(:method_a) { SomeRandomClass.instance_method :some_public_method }
    let(:method_b) { SomeRandomClass.method :some_class_method }

    it do
      expect(Delfos::MethodLogging::AddedMethods.instance.added_methods).to eq({})

      described_class.setup(klass, "some_public_method", klass.private_instance_methods, class_method: false)
      described_class.setup(klass, "some_class_method",  klass.private_methods,          class_method: true)

      result = Delfos::MethodLogging::AddedMethods.instance.added_methods

      expect(result["SomeRandomClass"]["InstanceMethod_some_public_method"].source_location).
        to eq [File.expand_path(__FILE__), $instance_method_line_number]

      expect(result["SomeRandomClass"]["ClassMethod_some_class_method"].source_location).
        to eq [File.expand_path(__FILE__), $class_method_line_number]
    end
  end

  describe ".perform" do
    let(:method_logging) do
      exclusion = lambda{|m| 
        ![:some_public_method, :some_externally_called_public_method].include?(m.name)
      }

      m = double("MethodLogging")
      allow(m).to receive(:include_file_in_logging?) {|f| f == __FILE__ }
      allow(m).to receive(:exclude?, &exclusion)
      m
    end

    before do
      Delfos.method_logging = method_logging
    end

    context "with a class with a private method" do
      def setup_method(m)
        described_class.setup(klass, m, klass.private_instance_methods, class_method: false)
      end

      before do
        setup_method("some_externally_called_public_method")
        setup_method("some_public_method")
      end

      it "includes public methods" do
        expect(method_logging).to receive(:log)
        some_random_instance.some_public_method
      end

      it "excludes private methods" do
        expect(method_logging).not_to receive(:log)

        setup_method("some_private_method")

        some_random_instance.send(:some_private_method)
      end

      it "sends the correct args to the method call_site_logger" do
        call_count = 0

        expect(method_logging).to receive(:log) do |call_site, object, called_method,  _class_method, _arguments|
          call_count += 1
          expect(object).to be_a SomeRandomClass
          expect(call_site).to be_a Delfos::MethodLogging::CodeLocation

          case call_count
          when 1
            expect(call_site.object.class.name).to match /RSpec::ExampleGroups/
            expect(called_method.name).to eq :some_externally_called_public_method
          when 2
            expect(called_method.name).to eq  :some_public_method
            expect(call_site.object.class).to eq SomeRandomClass
            expect(call_site.object).to eq object
          end
        end.twice

        setup_method("some_public_method")
        setup_method("some_externally_called_public_method")

        some_random_instance.some_externally_called_public_method
      end
    end
  end
end
