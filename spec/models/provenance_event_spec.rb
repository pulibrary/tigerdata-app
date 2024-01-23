# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProvenanceEvent, type: :model do
  it "A submission event has the expected values" do
    pe = described_class.new
    pe.event_type = ProvenanceEvent::SUBMISSION_EVENT_TYPE
    pe.event_details = "Requested by Joe Shmoe, 2023-01-19T12:00:00"
    pe.event_person = "abc123"
    pe.save
  end
  it "A status update event has the expected values" do
    pe = described_class.new
    pe.event_type = ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE
    pe.event_details = "The Status was updated from pending to approved"
    pe.event_person = "abc123"
    pe.save
  end
end
