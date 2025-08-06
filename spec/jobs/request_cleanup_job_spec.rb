# frozen_string_literal: true
require "rails_helper"

RSpec.describe RequestCleanupJob, type: :job do
  describe "#perform" do
    let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
    let(:empty_request) { Request.create }
    let(:invalid_request) { Request.create(project_title: "Invalid Request", data_sponsor: user.uid, data_manager: user.uid) }
    let(:valid_request) do
      Request.create(project_title: "Valid Request", data_sponsor: user.uid, data_manager: user.uid, departments: ["RDSS"],
                     quota: "500 GB", description: "A valid request",
                     project_folder: "valid_folder")
    end

    it "destroys requests with 6 or more errors that are not valid to submit" do
      empty_request.updated_at = 25.hours.ago
      empty_request.save

      expect(empty_request.updated_at < 24.hours.ago).to be true
      expect(empty_request.valid_title?).to be false
      expect { described_class.perform_now }.to change(Request, :count).by(-1)
    end

    it "does not destroy invalid requests with a title" do
      invalid_request.updated_at = 25.hours.ago
      invalid_request.save

      expect(invalid_request.updated_at < 24.hours.ago).to be true
      expect(invalid_request.valid_title?).to be true
      expect { described_class.perform_now }.not_to change(Request, :count)
    end

    it "does not destroy valid requests" do
      expect { described_class.perform_now }.not_to change(Request, :count)
    end
  end
end
