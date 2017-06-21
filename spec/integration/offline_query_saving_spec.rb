require "tempfile"

RSpec.describe "integration .finish!" do
  context "with offline query saving enabled" do
    let(:tempfile) { Tempfile.new }

    after do
      tempfile.close
      Delfos::Setup.reset_top_level_variables!
    end

    it "calling Delfos.finish! closes the file" do
      Delfos.setup! offline_query_saving: tempfile.path,
        application_directories: "fixtures"

      load "fixtures/a_usage.rb"

      lines = File.readlines(tempfile.path)

      # length of lines after first call stack completion
      expect(lines.length).to eq 8

      Delfos.finish!

      lines = File.readlines(tempfile.path)
      expect(lines.length).to eq 11

      query, params = lines.first.split("\t")

      expect(query).to include "MERGE (k0:Class {name: {k0}}) MERGE (k1:Class {name: {k1}})"

      expect(JSON.parse(params)).to match({
        "call_site_file" => "fixtures/a_usage.rb",
        "call_site_line_number" => 3,
        "called_method_file" => "fixtures/a.rb",
        "called_method_line_number" => 5,
        "called_method_name" => "some_method",
        "called_method_type" => "InstanceMethod",
        "container_method_file" => "fixtures/a_usage.rb",
        "container_method_line_number" => 3,
        "container_method_name" => "(main)",
        "container_method_type" => "InstanceMethod",
        "k0" => "Object",
        "k1" => "A",
        "stack_uuid" => anything,
        "step_number" => 1,
      })
    end


    let(:query) do
      <<-QUERY
     MATCH (a:Class{name: "A"})  -  [:OWNS]
       -> (ma:Method{type: "InstanceMethod", name: "some_method"})
     MATCH (b:Class{name: "B"})  -  [:OWNS]
       ->  (mb:Method{type: "InstanceMethod", name: "another_method"})
     MATCH (c:Class{name: "C"})  -  [:OWNS]
       ->  (mc:Method{type: "InstanceMethod", name: "method_with_no_more_method_calls"})

     RETURN
       count(ma), ma,
       count(mb), mb,
       count(mc), mc
      QUERY
    end

    it "executing Delfos.import_offline_queries!(filename)" do
      wipe_db!

      Delfos.setup! offline_query_saving: tempfile.path,
        application_directories: "fixtures"

      load "fixtures/a_usage.rb"

      Delfos.finish!
      Delfos.import_offline_queries(tempfile.path)

      result = Delfos::Neo4j.execute_sync(query).first
      a_method_count, method_a, b_method_count, method_b, c_method_count, method_c = result

      expect(a_method_count).to eq 1

      expect(method_a).to eq("file" => "fixtures/a.rb",
                             "line_number" => 5,
                             "name" => "some_method",
                             "type" => "InstanceMethod")

      expect(b_method_count).to eq 1
      expect(c_method_count).to eq 1
    end


  end
end
