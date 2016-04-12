require_relative "patching"
require_relative "patching_unstubbing_spec_helper"

#HACK this is awful
Delfos::Patching.extend Unstubbing::ClassMethods
Delfos::Patching.prepend Unstubbing::InstanceMethods

describe Delfos::Patching do
  after(:each) do
    described_class.unstub_all!
  end

  class SomeAnonymousClass
    def some_public_method
      some_private_method
    end

    private

    def some_private_method
      "private"
    end
  end

  describe ".perform" do
    context "with a class with a private method" do
      let(:klass) { SomeAnonymousClass }
      let(:some_anonymous_instance) { klass.new }

      before do
        allow_any_instance_of(described_class).to receive(:exclude?) do
          klass != SomeAnonymousClass
        end

        allow(Delfos::ExecutionChain).to receive(:pop)
      end

      it "includes public methods" do
        expect(Delfos::MethodLogging).to receive(:log)
        described_class.perform(klass, "some_public_method", klass.private_instance_methods, class_method: false)

        some_anonymous_instance.some_public_method
      end

      it "excludes private methods" do
        expect(Delfos::MethodLogging).not_to receive(:log)

        described_class.perform(klass, "some_private_method", klass.private_instance_methods, class_method: false)

        some_anonymous_instance.send(:some_private_method)
      end

      it "sends the correct args to the method logger" do
        expect(Delfos::MethodLogging).to receive(:log) do |object, args, keyword_args, block, class_method, stack, call_site_binding, original_method|
          expect(object).to be_a SomeAnonymousClass
          expect(original_method.name).to eq :some_public_method
        end

        described_class.perform(klass, "some_public_method", klass.private_instance_methods, class_method: false)

        some_anonymous_instance.some_public_method
      end
    end
  end
end
