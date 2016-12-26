# frozen_string_literal: true
require_relative "./method_cache"

module Delfos
  module Patching
    describe MethodCache do
      class SuperKlass
        $instance_method_line = __LINE__ + 1
        def some_method
        end

        $class_method_line = __LINE__ + 1
        def self.some_class_method
        end
      end

      class SubKlass < SuperKlass
        $sub_klass_class_method_not_in_super_klass_line = __LINE__ + 1
        def self.method_not_in_super_klass
        end

        $sub_klass_method_not_in_super_klass_line = __LINE__ + 1
        def method_not_in_super_klass
        end
      end

      let(:instance_method)           { SuperKlass.instance_method(:some_method).source_location }
      let(:class_method)              { SuperKlass.method(:some_class_method).source_location }
      let(:sub_klass_instance_method) { SubKlass.instance_method(:method_not_in_super_klass).source_location }
      let(:sub_klass_class_method)    { SubKlass.method(:method_not_in_super_klass).source_location }

      before do
        subject.append(SuperKlass, "ClassMethod_some_class_method", *class_method)
        subject.append(SuperKlass, "InstanceMethod_some_method", *instance_method)
        subject.append(SubKlass, "ClassMethod_method_not_in_super_klass", *sub_klass_class_method)
        subject.append(SubKlass, "InstanceMethod_method_not_in_super_klass", *sub_klass_instance_method)
      end

      describe "#append" do
        it "appends to the methods" do
          subject.append(SuperKlass, "B", "C", 23)
          expect(subject.added_methods["Delfos::Patching::SuperKlass"]).to include("B" => { file: "C", line_number: 23 })
        end

        it "doesn't replace existing definitions" do
          subject.append(SuperKlass, "B", "C", 1)
          subject.append(SuperKlass, "B", "D", 2)
          expect(subject.added_methods["Delfos::Patching::SuperKlass"]).to include("B" => { file: "C", line_number: 1 })
        end

        it do
          subject.append(SuperKlass, "B", "C", 1)
          subject.append(SuperKlass, "E", "F", 2)
          expect(subject.added_methods["Delfos::Patching::SuperKlass"]).to include("B" => { file: "C", line_number: 1 }, "E" => { file: "F", line_number: 2 })
        end
      end

      describe "#find" do
        def to_h(m)
          file, line_number = m
          { file: file, line_number: line_number }
        end

        it "handles ordinary method recording" do
          expect(subject.find(SuperKlass, "InstanceMethod_some_method")).to eq to_h instance_method
          expect(subject.find(SuperKlass, "ClassMethod_some_class_method")).to eq to_h class_method
        end

        it "returns the super class methods for sub classes" do
          expect(subject.find(SubKlass, "InstanceMethod_some_method")).to eq to_h instance_method
          expect(subject.find(SubKlass, "ClassMethod_some_class_method")).to eq to_h class_method
        end

        it "returns sub class methods for sub classes" do
          expect(subject.find(SubKlass, "InstanceMethod_method_not_in_super_klass")).to eq to_h sub_klass_instance_method
          expect(subject.find(SubKlass, "ClassMethod_method_not_in_super_klass")).to eq to_h sub_klass_class_method
        end
      end

      describe "#method_sources_for" do
        it do
          expect(subject.all_method_sources_for(SubKlass)).to include([__FILE__, $class_method_line])
          expect(subject.all_method_sources_for(SubKlass)).to include([__FILE__, $instance_method_line])
          expect(subject.all_method_sources_for(SubKlass)).to include([__FILE__, $sub_klass_method_not_in_super_klass_line])
          expect(subject.all_method_sources_for(SubKlass)).to include([__FILE__, $sub_klass_class_method_not_in_super_klass_line])
        end
      end
    end
  end
end
