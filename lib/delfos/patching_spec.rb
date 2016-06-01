require_relative "patching"
require_relative "patching_unstubbing_spec_helper"

#HACK this is awful
Delfos::Patching.extend Unstubbing::ClassMethods
Delfos::Patching.prepend Unstubbing::InstanceMethods

describe Delfos::Patching do
  class SomeRandomClass
    $class_method_line_number = __LINE__ + 1
    def self.some_class_method
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

  class SomeSubClass
  end


  let(:klass) { SomeRandomClass }
  let(:some_random_instance) { klass.new }

  before do
    allow_any_instance_of(described_class).to receive(:exclude?) do
      klass != SomeRandomClass
    end

    allow(Delfos::MethodLogging).to receive(:log)
    allow(Delfos::ExecutionChain).to receive(:pop)
  end

  describe ".added_methods" do
    let(:method_a) { SomeRandomClass.instance_method :some_public_method }
    let(:method_b) { SomeRandomClass.method :some_class_method  }

    after(:each) do
      described_class.unstub_all!
    end

    it do
      expect(described_class.added_methods).to eq({})

      described_class.perform(klass, "some_public_method", klass.private_instance_methods, class_method: false)
      described_class.perform(klass, "some_class_method",  klass.private_methods,          class_method: true)

      result = described_class.added_methods

      expect(result["SomeRandomClass"]["InstanceMethod_some_public_method"].source_location).
        to eq [File.expand_path(__FILE__), $instance_method_line_number]

      expect(result["SomeRandomClass"]["ClassMethod_some_class_method"].source_location).
        to eq [File.expand_path(__FILE__), $class_method_line_number]
    end
  end

  describe ".perform" do
    context "with a class with a private method" do
      it "includes public methods" do
        expect(Delfos::MethodLogging).to receive(:log)
        described_class.perform(klass, "some_public_method", klass.private_instance_methods, class_method: false)

        some_random_instance.some_public_method
      end

      it "excludes private methods" do
        expect(Delfos::MethodLogging).not_to receive(:log)

        described_class.perform(klass, "some_private_method", klass.private_instance_methods, class_method: false)

        some_random_instance.send(:some_private_method)
      end

      it "sends the correct args to the method logger" do
        expect(Delfos::MethodLogging).to receive(:log) do |object, args, keyword_args, block, class_method, stack, call_site_binding, original_method|
          expect(object).to be_a SomeRandomClass
          expect(original_method.name).to eq :some_public_method
        end

        described_class.perform(klass, "some_public_method", klass.private_instance_methods, class_method: false)

        some_random_instance.some_public_method
      end
    end
  end
end
