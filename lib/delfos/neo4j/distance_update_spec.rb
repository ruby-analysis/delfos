require_relative "distance_update"
require_relative "informer"
require_relative "../../delfos"
require "neo4j"

describe Delfos::Neo4j::DistanceUpdate do
  def preload_graph!
    Delfos.wipe_db!
    Delfos.reset!
    dirs = [File.expand_path("./fixtures/ruby/")]
    Delfos.setup! application_directories: dirs, logger: Delfos::Neo4j::Informer.new

    load "fixtures/ruby/efferent_coupling.rb"
    EfferentCoupling.new.lots_of_coupling
  end

  before(:all) do
    preload_graph!

    described_class.new.perform

    query = <<-QUERY
      MATCH 
        (klass)        - [:OWNS]      -> (caller),
        (caller)      <- [:CALLED_BY] -  (method_call),
        (method_call)  - [:CALLS]     -> (called),
        (called_klass) - [:OWNS]      -> (called)

        , (caller)  -   [:EFFERENT_COUPLING] -> (called)

      RETURN klass, caller, method_call, called, called_klass
    QUERY


    @result = ::Neo4j::Session.query(query)
  end

  it do
    props = @result.map(&:caller).map(&:props).uniq
    expect(props.length).to eq 1
  end

  it do
    props = @result.map(&:caller).map(&:props).uniq
    prop = props.first
    expect(prop[:file]).to match %r{fixtures/ruby/efferent_coupling\.rb}
    expect(prop).to include({name: "lots_of_coupling", line_number: "5"})
  end

  it do
    klasses = @result.map(&:klass).map(&:labels).flatten.uniq
    expect(klasses).to eq [:EfferentCoupling]
  end

  it do
    called_klasses = @result.map(&:called_klass).map(&:labels).flatten.uniq
    expect(called_klasses).to eq [:This, :That, :SomeOther, :SoMuchCoupling, :HereIsSomeMore]
  end

  describe "caller" do
    it do
      caller_props = @result.map(&:caller).map(&:props).flatten.uniq

      expect(caller_props).to eq [
        {:file        => "fixtures/ruby/efferent_coupling.rb",
         :name        => "lots_of_coupling",
         :line_number => "5"}
      ]
    end
  end

  it do
    called_props = @result.map(&:called).map(&:props).flatten.uniq

    expect(called_props).to eq [
      {:file => "ruby/this.rb", :name => "send_message",     :line_number => "2"},
      {:file => "ruby/this.rb", :name => "found_in_here",    :line_number => "9"},
      {:file => "ruby/this.rb", :name => "for_good_measure", :line_number => "13"}
    ]
  end
end
