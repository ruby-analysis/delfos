# frozen_string_literal: true
require_relative "method_override"

module Delfos
  module Patching
    describe MethodOverride do
      let(:klass) { SomeRandomClass }
      let(:instance) { klass.new }

      before do
        load "fixtures/method_override/some_random_class.rb"
        stub_const("Delfos::CallStack", double("CallStack class"))

        allow(MethodLogging).to receive(:exclude?) do
          klass != SomeRandomClass
        end

        allow(MethodLogging).to receive(:log)
        allow(CallStack).to receive(:pop)
        allow(CallStack).to receive(:push)
      end

      after(:each) do
        Delfos::Patching::Unstubber.unstub_all!
      end

      describe "Adding to the method cache" do
        let(:method_a) { SomeRandomClass.instance_method :some_public_method }
        let(:method_b) { SomeRandomClass.method :some_class_method }

        it do
          expect(MethodCache.instance.send(:added_methods)).to eq({})

          described_class.setup(klass, "some_public_method", class_method: false)
          described_class.setup(klass, "some_class_method",  class_method: true)

          result = MethodCache.instance.send(:added_methods)

          expect(result["SomeRandomClass"]["InstanceMethod_some_public_method"].source_location).
            to eq(["fixtures/method_override/some_random_class.rb", $instance_method_line_number])

          expect(result["SomeRandomClass"]["ClassMethod_some_class_method"].source_location).
            to eq([ "fixtures/method_override/some_random_class.rb", $class_method_line_number])
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

          pending "this test was broken - will fix soon - sends the correct args to the method call_site_logger" do
            calls = 0
            expect(Delfos::MethodLogging).to receive(:log) do |call_site, object, called_method, _class_method, _arguments|
              calls += 1

              case calls
              when 1
                expect(object).to be_a SomeRandomClass
                expect(call_site).to be_a Delfos::MethodLogging::CodeLocation

                expect(call_site.method_name).to eq "some_externally_called_public_method"
                expect(call_site.class_method).to eq false
                expect(call_site.method_type).to eq "InstanceMethod"
                expect(call_site.line_number).to eq $call_site_line_number
                expect(call_site.object).to be_a SomeRandomClass

                expect(called_method.name).to eq :some_public_method
              when 2
                expect(object).to be_a SomeRandomClass
              end
            end.twice

            instance.some_externally_called_public_method
            expect(calls).to eq 2
          end

          def setup_method(m)
            described_class.setup(klass, m, class_method: false)
          end
        end
      end
    end
  end
end
