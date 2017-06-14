# frozen_string_literal: true

require "delfos"

describe "integration with a customer call_stack_logger" do
  let(:call_site_logger) { double "call stack logger", log: nil, save_call_stack: nil }

  before do
    WebMock.disable_net_connect! allow_localhost: false

    Delfos.setup!(
      application_directories: ["fixtures"],
      call_site_logger: call_site_logger,
    )
  end

  after do
    Delfos.disable!
    WebMock.disable_net_connect! allow_localhost: true
  end

  context "with app code calling lib code which calls back into lib code" do
    it "logs the call sites" do
      cl = Delfos::MethodTrace::CodeLocation

      count = 0

      expect(call_site_logger).to receive(:log) do |call_site|
        count = count + 1

        case count
        when 1
          expect(call_site.summary).to eq({
            container_method:  "fixtures/app/include_this/start_here.rb:0 Object#(main)",
            call_site:         "fixtures/app/include_this/start_here.rb:3",
            called_method:     "fixtures/app/include_this/called_app_class.rb:5 IncludeThis::CalledAppClass#some_called_method",
          })

        when 2
          expect(call_site.summary).to eq({
            container_method: "fixtures/app/include_this/called_app_class.rb:9 IncludeThis::CalledAppClass#next_method",
            call_site:        "fixtures/app/include_this/called_app_class.rb:10",
            called_method:    "fixtures/app/include_this/called_app_class.rb:13 IncludeThis::CalledAppClass#final_method",
          })
        end
        expect(call_site)                  .to be_a cl::CallSite
      end.exactly(2).times

      load "fixtures/app/include_this/start_here.rb"
    end

    it "Saves the call stack" do
      count = 0

      expect(call_site_logger).to receive(:save_call_stack) do |call_sites, execution_count|
        count = count + 1

        case count
        when 1
          expect(call_sites.length).to eq 1

          expect(call_sites.first.summary).to eq({
            container_method: "fixtures/app/include_this/start_here.rb:0 Object#(main)",
            call_site:        "fixtures/app/include_this/start_here.rb:3",
            called_method:    "fixtures/app/include_this/called_app_class.rb:5 IncludeThis::CalledAppClass#some_called_method",
          })
        when 2
          expect(call_sites.length).to eq 1

          expect(call_sites.last.summary).to eq({
            container_method: "fixtures/app/include_this/called_app_class.rb:9 IncludeThis::CalledAppClass#next_method",
            call_site:        "fixtures/app/include_this/called_app_class.rb:10",
            called_method:    "fixtures/app/include_this/called_app_class.rb:13 IncludeThis::CalledAppClass#final_method",
          })
        end

        expect(execution_count)   .to eq 1
      end.exactly(:once)

      load "fixtures/app/include_this/start_here.rb"
    end
  end
end
