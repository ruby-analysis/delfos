# frozen_string_literal: true

require "rails_helper"

describe User do
  let(:invalid_attributes) { { username: "Example", doesnt_exist: "something else" } }

  it "allows incorrect attributes to be used in mocks" do
    user = mock("User", invalid_attributes)
    expect(user.username).to eq "Example"
    expect(user.doesnt_exist).to eq "something else"
  end

  it "blows up when using the real thing" do
    boom = -> { User.new invalid_attributes }
    expect(boom).to raise_error ActiveModel::UnknownAttributeError
  end
end
