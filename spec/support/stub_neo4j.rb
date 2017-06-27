# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength,Metrics/AbcSize
module DelfosSpecs
  def self.stub_neo4j(include_path: "fixtures")
    Module.new do
      define_singleton_method :included do |base|
        base.class_eval do
          let(:call_site_logger) { double "call stack logger", log: nil, save_call_stack: nil, finish!: nil }

          before do
            WebMock.disable_net_connect! allow_localhost: false

            Delfos.configure do |c|
              c.include = include_path
              allow(c).to receive(:call_site_logger).and_return call_site_logger
            end

            Delfos.start!
          end

          after do
            Delfos.finish!
            WebMock.disable_net_connect! allow_localhost: true
          end
        end
      end
    end
  end
end
