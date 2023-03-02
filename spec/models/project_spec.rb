# frozen_string_literal: true
require "rails_helper"

RSpec.describe Project, type: :model do
  it "allows good data creation" do
    expect do
      Project.create!(data: { "name": "test123" })
    end.not_to raise_error
  end

  it "flags bad data creation" do
    expect do
      Project.create!(data: { "wrong": "test123" })
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "allows good name setting" do
    p = Project.new
    p.name = "valid"
    expect do
      p.save!
    end.not_to raise_error
  end

  it "flags bad name setting" do
    p = Project.new
    p.name = ["invalid"]
    expect do
      p.save!
    end.to raise_error(ActiveRecord::RecordInvalid)
  end
end
