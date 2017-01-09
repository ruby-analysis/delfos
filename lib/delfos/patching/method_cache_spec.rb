# frozen_string_literal: true
require_relative "./method_cache"

module Delfos
  module Patching
    describe MethodCache do
      class SuperKlass
        $instance_method_line = __LINE__ + 1
        def some_method; end

        $class_method_line = __LINE__ + 1
        def self.some_class_method
        end
      end

      class SubKlass < SuperKlass
        $sub_klass_class_method_not_in_super_klass_line = __LINE__ + 1
        def self.method_not_in_super_klass
        end

        $sub_klass_method_not_in_super_klass_line = __LINE__ + 1
        def method_not_in_super_klass; end
      end

      let(:instance_method)           { SuperKlass.instance_method(:some_method) }
      let(:class_method)              { SuperKlass.method(:some_class_method) }
      let(:sub_klass_instance_method) { SubKlass.instance_method(:method_not_in_super_klass) }
      let(:sub_klass_class_method)    { SubKlass.method(:method_not_in_super_klass) }

      describe "#append" do
        it "appends to the methods" do
          subject.append(klass: SuperKlass, method: instance_method)
          result = subject.find(klass: SuperKlass, method_name: "some_method", class_method: false)
          expect(result).to eq instance_method
        end

        it "doesn't replace existing definitions" do
          subject.append(klass: SuperKlass, method: instance_method)
          result = subject.find(klass: SuperKlass, method_name: "some_method", class_method: false)
          expect(result).to eq instance_method

          dummy_instance_method = double "Dummy Instance Method", name: "some_method", class_method: false
          subject.append(klass: SuperKlass, method: dummy_instance_method)

          result = subject.find(klass: SuperKlass, method_name: "some_method", class_method: false)
          expect(result).to eq instance_method
        end
      end

      describe "#find" do
        before do
          subject.append(klass: SuperKlass, method: class_method)
          subject.append(klass: SuperKlass, method: instance_method)
          subject.append(klass: SubKlass,   method: sub_klass_class_method)
          subject.append(klass: SubKlass,   method: sub_klass_instance_method)
        end

        it "handles ordinary method recording" do
          expect(subject.find(klass: SuperKlass, class_method: false, method_name: "some_method")).to eq instance_method
          expect(subject.find(klass: SuperKlass, class_method: true, method_name: "some_class_method")).to eq class_method
        end

        it "returns the super class methods for sub classes" do
          expect(subject.find(klass: SubKlass, class_method: false, method_name: "some_method")).to eq instance_method
          expect(subject.find(klass: SubKlass, class_method: true, method_name: "some_class_method")).to eq class_method
        end

        it "returns sub class methods for sub classes" do
          expect(subject.find(klass: SubKlass, class_method: false, method_name: "method_not_in_super_klass")).to eq sub_klass_instance_method
          expect(subject.find(klass: SubKlass, class_method: true, method_name: "method_not_in_super_klass")).to eq sub_klass_class_method
        end
      end

      describe "#files_for" do
        it do
          subject.append(klass: SubKlass, method: sub_klass_instance_method)
          expect(subject.files_for(SubKlass)).to include(__FILE__)
        end
      end
    end
  end
end
