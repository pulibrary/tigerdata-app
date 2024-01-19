# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProvenanceEvent, type: :model do
  it "has the expected fields" do
    pe = described_class.new
    pe.event_type = "Submission"
    pe.event_details = "Requested by Joe Shmoe, 2023-01-19T12:00:00"
    pe.event_person = "abc123"
    pe.save
  end
end
