# frozen_string_literal: true
require "rails_helper"

RSpec.describe ListProjectContentsJob do
  let(:user) { FactoryBot.create(:user) }
  let(:user_id) { user.id }
  let(:project_title) { "Test Project" }

  describe "#perform_now" do
    it "updates the UserJob#completed_at attribute" do
      described_class.perform_now(user_id:, project_title:)
    end

    context "when an invalid User ID is specified" do
      let(:user_id) { "invalid" }
      it "raises an error" do
        expect { described_class.perform_now(user_id:, project_title:) }.to raise_error(ArgumentError, /Failed to retrieve the User for the ID #{user_id}/)
      end
    end
  end
end
