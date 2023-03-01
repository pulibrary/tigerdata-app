# frozen_string_literal: true
require "rails_helper"

RSpec.describe Role, type: :model do
  it "has seed data" do
    expect(Role.all.size).to eq(3)
  end
end
