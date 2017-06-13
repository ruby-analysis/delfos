# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Delfos integration" do
  before do
    Delfos::Neo4j.execute_sync "MATCH (n)-[r]-(o) DELETE n,r,o"
    Delfos::Neo4j.execute_sync "MATCH (n) DELETE n"
    Delfos.setup!
    load "./app/models/user.rb"
    u = User.new name: "John Smith"
    u.my_name

    Delfos::Neo4j.flush!
  end
  it do
    1
  end
end
