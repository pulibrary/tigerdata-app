# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProvenanceEvent, type: :model do
    let(:current_user) { FactoryBot.create(:user, uid: "hc1234") }
    let(:project) { Project.new }
    before do
        params = {data_sponsor: "abc", data_manager: "def", departments: "dep", directory: "dir", title: "title abc", description: "description 123", status: "pending" }
        project_metadata = ProjectMetadata.create( params: params )
      end

    context "when a project is submitted" do
        it "creates a provenance create event" do
            expect(provenance_event_values.event_type).to eq nil
            expect(provenance_event_values.event_type).to 
            provenance_event_values.event_type = "Submission"
            expect(provenance_event_values.event_type).to eq "Submission"
        end
    end
end