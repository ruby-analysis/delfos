require "tempfile"

RSpec.describe "integration .finish!" do
  context "with offline query saving enabled" do
    let(:tempfile) { Tempfile.new }

    after do
      tempfile.close
    end

    it "calling Delfos.finish! closes the file" do
      Delfos.setup! offline_query_saving: tempfile.path,
        application_directories: "fixtures"

      load "fixtures/a_usage.rb"

      lines = File.readlines(tempfile.path)

      # length of lines after first call stack completion
      expect(lines.length).to eq 7

      Delfos.finish!

      lines = File.readlines(tempfile.path)
      expect(lines.length).to eq 11
      query, params, message = lines.first.split("\t")

      expect(query).to include "MERGE (k0:Class {name: {k0}}) MERGE (k1:Class {name: {k1}})"

      expect(message).to eq "not_imported\n"
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
  end
end
