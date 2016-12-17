# frozen_string_literal: true
require_relative "execution_chain"

describe Delfos::ExecutionChain do
  let(:execution_chain_query) { double "execution chain query", query: query, params: params }
  let(:params) { {some: "params"} }
  let(:query) { "some query" }

  before do
    Delfos::ExecutionChain.reset!
    allow(Delfos::Neo4j::ExecutionChainQuery).to receive(:new).and_return(execution_chain_query)
    allow(Delfos::Neo4j).to receive(:execute).with(query, params)
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
      expect(subject.stack_depth).to eq 0
      subject.push(anything)
      expect(subject.stack_depth).to eq 1

      subject.push(anything)
      expect(subject.stack_depth).to eq 2
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
      expect(Delfos::Neo4j::ExecutionChainQuery).to have_received(:new).with([1,2,3],1)
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
      expect(subject.stack_depth).to eq 0 # sanity check
      expect(subject.step_count).to eq 0 # step count is reset
    end

    it "decrements the stack depth" do
      expect(subject.stack_depth).to eq 0
      subject.push(anything)
      expect(subject.stack_depth).to eq 1

      subject.push(anything)
      expect(subject.stack_depth).to eq 2

      subject.pop
      expect(subject.stack_depth).to eq 1

      subject.pop
      expect(subject.stack_depth).to eq 0

      # stays at zero without going negative
      expect { subject.pop }.to raise_error Delfos::ExecutionChain::PoppingEmptyStackError
    end

    it "increments the execution counter only when the stack depth increases from 0 to 1" do
      expect(subject.execution_count).to eq 0

      subject.push(anything)
      expect(subject.execution_count).to eq 1
      expect(subject.stack_depth).to eq 1

      subject.push(anything)
      expect(subject.execution_count).to eq 1
      expect(subject.stack_depth).to eq 2

      subject.pop
      expect(subject.stack_depth).to eq 1
      expect(subject.execution_count).to eq 1 # remains same

      subject.pop
      expect(subject.stack_depth).to eq 0
      expect(subject.execution_count).to eq 1 # remains same until next push(anything)

      subject.push(anything)
      expect(subject.stack_depth).to eq 1
      expect(subject.execution_count).to eq 2 # now it increments
    end
  end
end
