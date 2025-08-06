# frozen_string_literal: true
require "rails_helper"

RSpec.describe RequestCleanupJob, type: :job do
  let!(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let!(:empty_request) { Request.create(request_title: "") }
  let!(:invalid_request) { Request.create(request_title: "Invalid Request", data_sponsor: user.uid, data_manager: user.uid) }
  let!(:valid_request) do
    Request.create(request_title: "Valid Request", data_sponsor: user.uid, data_manager: user.uid, departments: ["RDSS"],
                   quota: "500 GB", description: "A valid request",
                   project_folder: "valid_folder")
  end

  describe "#perform" do
    it "destroys requests with 6 or more errors that are not valid to submit" do
      empty_request.errors.add(:base, "Test error")
      empty_request.errors.add(:base, "Test error")
      empty_request.errors.add(:base, "Test error")
      empty_request.errors.add(:base, "Test error")
      empty_request.errors.add(:base, "Test error")
      empty_request.errors.add(:base, "Test error")

      empty_request.updated_at = 25.hours.ago
      empty_request.save

      expect { described_class.perform_now }.to change(Request, :count).by(-1)
    end

    it "does not destroy requests with less than 6 errors" do
      invalid_request.errors.add(:base, "Test error")
      invalid_request.errors.add(:base, "Test error")

      invalid_request.updated_at = 25.hours.ago
      invalid_request.save

      expect { described_class.perform_now }.not_to change(Request, :count)
    end

    it "does not destroy valid requests" do
      expect { described_class.perform_now }.not_to change(Request, :count)
    end
  end
end
