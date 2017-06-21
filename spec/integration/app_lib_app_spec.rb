# frozen_string_literal: true

require "delfos"

describe "integration with a custom call_stack_logger" do
  let(:call_site_logger) { double "call stack logger", log: nil, save_call_stack: nil }

  before do
    WebMock.disable_net_connect! allow_localhost: false

    Delfos.setup!(
      application_directories: ["fixtures/app/include_this"],
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
            container_method:  "fixtures/app/include_this/start_here.rb:3 Object#(main)",
            call_site:         "fixtures/app/include_this/start_here.rb:3",
            called_method:     "include_this/called_app_class.rb:5 IncludeThis::CalledAppClass#some_called_method",
          })

        when 2
          expect(call_site.summary).to eq({
            :container_method => "exclude_this/exclude_this.rb:10 ExcludeThis#further",
            :call_site => "exclude_this/exclude_this.rb:11",
            :called_method => "include_this/called_app_class.rb:9 IncludeThis::CalledAppClass#next_method",
          })

        when 3
          expect(call_site.summary).to eq({
            container_method: "include_this/called_app_class.rb:9 IncludeThis::CalledAppClass#next_method",
            call_site:        "include_this/called_app_class.rb:10",
            called_method:    "include_this/called_app_class.rb:13 IncludeThis::CalledAppClass#penultimate",
          })
        when 4
          expect(call_site.summary).to eq({
            container_method: "include_this/called_app_class.rb:13 IncludeThis::CalledAppClass#penultimate",
            call_site:        "include_this/called_app_class.rb:14",
            called_method:    "include_this/called_app_class.rb:17 IncludeThis::CalledAppClass#final_method",
          })
        end
        expect(call_site)                  .to be_a cl::CallSite
      end.exactly(4).times

      load "fixtures/app/include_this/start_here.rb"
    end
  end
end
