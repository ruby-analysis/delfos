# frozen_string_literal: true
require_relative "distance_update"
require_relative "informer"
require_relative "../../delfos"
require "neo4j"

describe Delfos::Neo4j::DistanceUpdate do
  def preload_graph!
    Delfos.wipe_db!
    Delfos.reset!
    dirs = ["fixtures/ruby/"]
    Delfos.setup! application_directories: dirs

    load "fixtures/ruby/efferent_coupling.rb"
    EfferentCoupling.new.lots_of_coupling
  end

  before(:all) do
    preload_graph!

    described_class.new.perform

    query = <<-QUERY
      MATCH
        (klass)        - [:OWNS]      -> (call_site),
        (call_site)      <- [:CALLED_BY] -  (method_call),
        (method_call)  - [:CALLS]     -> (called),
        (called_klass) - [:OWNS]      -> (called)

        , (call_site)  -   [:EFFERENT_COUPLING] -> (called)

      RETURN klass, call_site, method_call, called, called_klass
    QUERY

    @result = ::Neo4j::Session.query(query)
  end

  it "records the Classes" do
    klasses = @result.map(&:klass).map(&:labels).flatten.uniq
    expect(klasses).to eq [:EfferentCoupling]
  end

  it "records the called classes" do
    called_klasses = @result.map(&:called_klass).map(&:labels).flatten.uniq
    expect(called_klasses).to match_array [:This, :That, :SomeOther, :SoMuchCoupling, :HereIsSomeMore]
  end

  describe "call_site" do
    it "returns the call_site" do
      props = @result.map(&:call_site).map(&:props).uniq
      expect(props.length).to eq 1
    end

    it "records the call_site details" do
      call_site_props = @result.map(&:call_site).map(&:props).flatten.uniq

      expect(call_site_props).to eq [
        { file: "fixtures/ruby/efferent_coupling.rb",
          name: "lots_of_coupling",
          line_number: "5" },
      ]
    end
  end

  it "records the called method details" do
    called_props = @result.map(&:called).map(&:props).flatten.uniq

    expect(called_props).to match_array [
      { file: "ruby/this.rb", name: "send_message",     line_number: "2" },
      { file: "ruby/this.rb", name: "found_in_here",    line_number: "9" },
      { file: "ruby/this.rb", name: "for_good_measure", line_number: "13" },
    ]
  end

  describe "#determine_full_path" do
    before do
      Delfos.setup! application_directories: ["fixtures/ruby"]
    end

    it do
      result = subject.determine_full_path("/ruby/this.rb")

      expect(result.to_s).to eq File.expand_path("fixtures/ruby/this.rb").to_s
    end
  end
end
