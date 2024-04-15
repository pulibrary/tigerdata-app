# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProvenanceEvent, type: :model do
  context "when a project is submitted" do
    # When a project is submitted, it gets a submisssion event and a
    # a status update event to mark is as pending
    it "makes a provenance event recording the project submission" do
      pe = described_class.new
      pe.event_type = ProvenanceEvent::SUBMISSION_EVENT_TYPE
      pe.event_details = "Requested by Joe Shmoe, 2023-01-19T12:00:00"
      pe.event_person = "abc123"
      pe.save
      expect(pe.event_type).to eq(ProvenanceEvent::SUBMISSION_EVENT_TYPE)
    end
    it "makes a provenance event recording the status being set to pending" do
      pe = described_class.new
      pe.event_type = ProvenanceEvent::APPROVAL_EVENT_TYPE
      pe.event_details = "Approved by Jane Doe, 2023-01-19T12:00:00"
      pe.event_person = "abc123"
      pe.save
      expect(pe.event_type).to eq(ProvenanceEvent::APPROVAL_EVENT_TYPE)
    end
  end
  context "when a project is approved" do
    it "creates an approval event" do
      pe = described_class.new
      pe.event_type = ProvenanceEvent::APPROVAL_EVENT_TYPE
      pe.event_details = "The Status was updated from pending to approved"
      pe.event_person = "abc123"
      pe.save
      expect(pe.event_type).to eq(ProvenanceEvent::APPROVAL_EVENT_TYPE)
    end
  end
  context "when a project is made active" do
    it "creates an active event type" do
      pe = described_class.new
      pe.event_type = ProvenanceEvent::ACTIVE_EVENT_TYPE
      pe.event_details = "The Status was updated from approved to active"
      pe.event_person = "abc123"
      pe.save
      expect(pe.event_type).to eq(ProvenanceEvent::ACTIVE_EVENT_TYPE)
    end
  end
  context "when a project status is updated" do
    it "creates a status update event" do
      pe = described_class.new
      pe.event_type = ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE
      pe.event_details = "The Status was updated from pending to approved"
      pe.event_person = "abc123"
      pe.save
      expect(pe.event_type).to eq(ProvenanceEvent::STATUS_UPDATE_EVENT_TYPE)
    end
  end
end
