# frozen_string_literal: true
require_relative "method_override"

module Delfos
  module Patching
    describe MethodOverride do
      require_relative "unstubbing_spec_helper"
      # HACK: this is awful - see unstubbing_spec_helper
      described_class.extend  Unstubbing::ClassMethods
      described_class.prepend Unstubbing::InstanceMethods

      class SomeRandomClass
        $class_method_line_number = __LINE__ + 1
        def self.some_class_method
        end

        def some_externally_called_public_method
          $call_site_line_number = __LINE__ + 1
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
      let(:instance) { klass.new }

      before do
        stub_const("Delfos::CallStack", double("CallStack class"))

        allow(MethodLogging).to receive(:exclude?) do
          klass != SomeRandomClass
        end

        allow(MethodLogging).to receive(:log)
        allow(CallStack).to receive(:pop)
        allow(CallStack).to receive(:push)
      end

      after(:each) do
        described_class.unstub_all!
      end

      describe "Adding to the method cache" do
        let(:method_a) { SomeRandomClass.instance_method :some_public_method }
        let(:method_b) { SomeRandomClass.method :some_class_method }

        it do
          expect(MethodCache.instance.added_methods).to eq({})

          described_class.setup(klass, "some_public_method", klass.private_instance_methods, class_method: false)
          described_class.setup(klass, "some_class_method",  klass.private_methods,          class_method: true)

          result = MethodCache.instance.added_methods

          expect(result["Delfos::Patching::SomeRandomClass"]["InstanceMethod_some_public_method"].source_location).
            to eq [File.expand_path(__FILE__), $instance_method_line_number]

          expect(result["Delfos::Patching::SomeRandomClass"]["ClassMethod_some_class_method"].source_location).
            to eq [File.expand_path(__FILE__), $class_method_line_number]
        end
      end

      describe ".perform" do
        let(:call_site_logger) { double "Call Site Logger" }

        before do
          exclusion = lambda do |m|
            ![:some_public_method, :some_externally_called_public_method].include?(m.name)
          end

          allow(MethodLogging).to receive(:include_file?) { |f| f == __FILE__ }
          allow(MethodLogging).to receive(:exclude?, &exclusion)

          Delfos.call_site_logger = call_site_logger
        end

        context "with a class with a private method" do
          before do
            setup_method("some_externally_called_public_method")
            setup_method("some_public_method")
          end

          it "sends the correct args to the method call_site_logger" do
            expect(Delfos::MethodLogging).to receive(:log) do |call_site, object, called_method, _class_method, _arguments|
              expect(object).to be_a SomeRandomClass
              expect(call_site).to be_a Delfos::MethodLogging::CodeLocation


              expect(call_site.method_name).to eq "some_externally_called_public_method"
              expect(call_site.class_method).to eq false
              expect(call_site.method_type).to eq "InstanceMethod"
              expect(call_site.line_number).to eq $call_site_line_number
              expect(call_site.object).to be_a SomeRandomClass

              expect(called_method.name).to eq :some_public_method
            end
            setup_method("some_public_method")
            setup_method("some_externally_called_public_method")

            instance.some_externally_called_public_method
          end

          it "excludes private methods" do
            expect(method_logging).not_to receive(:log)

            setup_method("some_private_method")

            instance.send(:some_private_method)
          end

          def setup_method(m)
            described_class.setup(klass, m, klass.private_instance_methods, class_method: false)
          end
        end
      end
    end
  end
end
