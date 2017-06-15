# frozen_string_literal: true

require "delfos"

describe "integration with a custom call_stack_logger" do
  let(:call_site_logger) { double "call stack logger", log: nil, save_call_stack: nil }

  before do
    WebMock.disable_net_connect! allow_localhost: false

    Delfos.setup!(
      application_directories: ["fixtures/"],
      call_site_logger: call_site_logger,
    )
  end

  after do
    Delfos.disable!
    WebMock.disable_net_connect! allow_localhost: true
  end

  let(:cl) { Delfos::MethodTrace::CodeLocation }

  context "with distantly handled exceptions" do
    let(:code_to_run) { "./fixtures/with_distantly_handled_exception.rb" }

    it "still logs correctly" do
      count = 0

      expect(call_site_logger).to receive(:log) do |call_site|
        count = count + 1

        case count
        when 1
          expect(call_site.summary).to eq({
            container_method:  "fixtures/with_distantly_handled_exception.rb:21 Object#(main)",
            call_site:         "fixtures/with_distantly_handled_exception.rb:21",
            called_method:     "fixtures/with_distantly_handled_exception.rb:1 Object#outer",
          })

        when 2
          expect(call_site.summary).to eq({
            container_method:  "fixtures/with_distantly_handled_exception.rb:1 Object#outer",
            call_site:         "fixtures/with_distantly_handled_exception.rb:2",
            called_method:     "fixtures/with_distantly_handled_exception.rb:5 Object#inner",
          })
        when 3
          expect(call_site.summary).to eq({
            container_method:  "fixtures/with_distantly_handled_exception.rb:5 Object#inner",
            call_site:         "fixtures/with_distantly_handled_exception.rb:6",
            called_method:     "fixtures/with_distantly_handled_exception.rb:9 Object#wait_for_it___",
          })
        when 3
          expect(call_site.summary).to eq({
            container_method:  "fixtures/with_distantly_handled_exception.rb:9 Object#wait_for_it___",
            call_site:         "fixtures/with_distantly_handled_exception.rb:10",
            called_method:     "fixtures/with_distantly_handled_exception.rb:13 Object#boom",
          })
        end
      end.exactly(5).times

      load code_to_run
    end

    it "records execution chains" do
      count = 0

      expect(call_site_logger).to receive(:save_call_stack) do |call_sites, execution_count|
        if count.zero?
          count = count + 1
          expect(call_sites.length).to eq 4
        else
          expect(call_sites.length).to eq 1
        end
      end.exactly(:twice)

      load code_to_run
    end
  end

  context "with code that raises and rescues" do
    let(:code_to_run) { "fixtures/with_raise.rb" }

    it "logs the call sites" do
      count = 0

      expect(call_site_logger).to receive(:log) do |call_site|
        count = count + 1

        case count
        when 1
          expect(call_site.summary).to eq({
            container_method:  "fixtures/with_raise.rb:13 Object#(main)",
            call_site:         "fixtures/with_raise.rb:13",
            called_method:     "fixtures/with_raise.rb:5 Object#execution_1",
          })

        when 2
          expect(call_site.summary).to eq({
            container_method: "fixtures/with_raise.rb:5 Object#execution_1",
            call_site:        "fixtures/with_raise.rb:6",
            called_method:    "fixtures/with_raise.rb:1 Object#boom",
          })
        when 3
          expect(call_site.summary).to eq({
            container_method: "fixtures/with_raise.rb:5 Object#execution_1",
            call_site:        "fixtures/with_raise.rb:7",
            called_method:    "fixtures/with_raise.rb:10 Object#another_method",
          })
        when 4
          expect(call_site.summary).to eq({
            container_method: "fixtures/with_raise.rb:14 Object#(main)",
            call_site:        "fixtures/with_raise.rb:14",
            called_method:    "fixtures/with_raise.rb:10 Object#another_method",
          })
        end
        expect(call_site).to be_a cl::CallSite
      end.exactly(4).times

      load code_to_run
    end

    it "Saves the call stack" do
      count = 0

      expect(call_site_logger).to receive(:save_call_stack) do |call_sites, execution_count|
        count = count + 1

        case count
        when 1

          expect(call_sites.first.summary).to eq({
            container_method: "fixtures/with_raise.rb:13 Object#(main)",
            call_site:        "fixtures/with_raise.rb:13",
            called_method:    "fixtures/with_raise.rb:5 Object#execution_1",
          })

          expect(call_sites.length).to eq 3

        when 2
          expect(call_sites.first.summary).to eq({
            call_site:        "fixtures/with_raise.rb:14",
            called_method:    "fixtures/with_raise.rb:10 Object#another_method",
            container_method: "fixtures/with_raise.rb:14 Object#(main)",
          })
          expect(call_sites.length).to eq 1

        end

      end.exactly(:twice)

      load code_to_run
    end
  end
end
