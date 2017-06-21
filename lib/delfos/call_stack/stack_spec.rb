# frozen_string_literal: true

require_relative "../call_stack"
require_relative "stack"

module Delfos
  module CallStack
    describe Stack do
      before do
        CallStack.reset!
      end

      describe "#push(anything)" do
        it "adds the list of things you pass to it" do
          subject.push(1)
          subject.push(2)
          subject.pop
          subject.push(anything)
          subject.push(3)

          expect(subject.call_sites).to eq [1, 2, anything, 3]
        end

        it "increments the stack depth each time" do
          expect(subject.height).to eq 0
          subject.push(anything)
          expect(subject.height).to eq 1

          subject.push(anything)
          expect(subject.height).to eq 2
        end

        it "increments the step counter each time" do
          subject.push(anything)
          expect(subject.step_count).to eq 1

          subject.push(anything)
          expect(subject.step_count).to eq 2
        end

        it "increments the execution counter only once" do
          expect(subject.execution_count).to eq 0

          subject.push(anything)
          expect(subject.execution_count).to eq 1

          subject.push(anything)
          expect(subject.execution_count).to eq 1
        end
      end

      describe "#pop" do
        it "clears the call site list only on resetting" do
          subject.push(1)
          subject.push(2)
          subject.push(3)
          expect(subject.call_sites).to eq [1, 2, 3]

          subject.pop
          expect(subject.call_sites).to eq [1, 2, 3]

          subject.pop
          subject.pop
          expect(subject.call_sites).to eq []
        end

        context "with a callback" do
          let(:callback) { double("callback", call: nil) }
          subject { described_class.new(on_empty: callback) }

          it "calls the callback on empty" do
            subject.push(anything)
            subject.push(anything)
            expect(callback).not_to have_received(:call)

            subject.pop
            expect(callback).not_to have_received(:call)
            subject.pop
            expect(callback).to have_received(:call)
          end
        end

        it "only decrements the step counter once the stack depth decrements to 0" do
          expect(subject.step_count).to eq 0

          subject.push(anything)
          expect(subject.step_count).to eq 1

          subject.push(anything)
          expect(subject.step_count).to eq 2

          subject.pop
          expect(subject.step_count).to eq 2

          subject.push(anything)
          expect(subject.step_count).to eq 3

          2.times { subject.pop }
          expect(subject.height).to eq 0 # sanity check
          expect(subject.step_count).to eq 0 # step count is reset
        end

        it "decrements the stack depth" do
          expect(subject.height).to eq 0
          subject.push(anything)
          expect(subject.height).to eq 1

          subject.push(anything)
          expect(subject.height).to eq 2

          subject.pop
          expect(subject.height).to eq 1

          subject.pop
          expect(subject.height).to eq 0

          # stays at zero without going negative
          expect { subject.pop }.to raise_error Delfos::CallStack::PoppingEmptyStackError
        end

        it "increments the execution counter only when the stack depth increases from 0 to 1" do
          expect(subject.execution_count).to eq 0

          subject.push(anything)
          expect(subject.execution_count).to eq 1
          expect(subject.height).to eq 1

          subject.push(anything)
          expect(subject.execution_count).to eq 1
          expect(subject.height).to eq 2

          subject.pop
          expect(subject.height).to eq 1
          expect(subject.execution_count).to eq 1 # remains same

          subject.pop
          expect(subject.height).to eq 0
          expect(subject.execution_count).to eq 1 # remains same until next push(anything)

          subject.push(anything)
          expect(subject.height).to eq 1
          expect(subject.execution_count).to eq 2 # now it increments
        end
      end
    end
  end
end
