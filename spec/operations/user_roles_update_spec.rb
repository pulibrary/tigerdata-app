# frozen_string_literal: true
require "rails_helper"

RSpec.describe UserRolesUpdate, type: :operation, integration: true do
  let!(:researcher) { FactoryBot.create(:user, uid: "libtigerdatadev", mediaflux_session: SystemUser.mediaflux_session) }
  subject { described_class.new } # Or initialize with dependencies if any

  describe "#call" do
    context "Success case" do
      it "updates a user's roles" do
        result = described_class.new.call(user: researcher)
        expect(result).to be_success
        user = result.value!
        # it gets the session information not based on the uid
        expect(user.developer).to be_truthy
        expect(user.sysadmin).to be_truthy
        expect(user.trainer).to be_falsey
      end

      it "does not call save if it is not needed" do
        # make sure the user matches with the mediaflux data
        researcher.developer = true
        researcher.sysadmin = true
        researcher.created_at = "abc" # cause an exception if was called save
        result = described_class.new.call(user: researcher)
        expect(result).to be_success
        user = result.value!
        expect(user.developer).to be_truthy
        expect(user.sysadmin).to be_truthy
        expect(user.trainer).to be_falsey
      end
    end
    context "Failure cases" do
      it "returns a failure for user save errors" do
        researcher.created_at = "abc" # case an exception on save
        result = described_class.new.call(user: researcher)
        expect(result).not_to be_success
        error_message = result.failure
        expect(error_message).to include("Error updating user roles! error: PG::NotNullViolation")
        researcher.reload
        expect(researcher.developer).to be_falsey
        expect(researcher.sysadmin).to be_falsey
        expect(researcher.trainer).to be_falsey
      end

      it "returns a failure for mediaflux session nil" do
        researcher.mediaflux_session = nil
        result = described_class.new.call(user: researcher)
        expect(result).not_to be_success
        error_message = result.failure
        expect(error_message).to eq("UserRolesUpdate called with for a user without a Mediaflux session")
        researcher.reload
        expect(researcher.developer).to be_falsey
        expect(researcher.sysadmin).to be_falsey
        expect(researcher.trainer).to be_falsey
      end

      it "returns a failure for an invalid user" do
        invalid_request = Mediaflux::ActorSelfDescribeRequest.new(session_token: "abc123")
        allow(Mediaflux::ActorSelfDescribeRequest).to receive(:new).and_return(invalid_request)
        allow(invalid_request).to receive(:error?).and_return(true)
        allow(invalid_request).to receive(:response_error).and_return("ERROR")
        result = described_class.new.call(user: researcher)
        expect(result).not_to be_success
        error_message = result.failure
        expect(error_message).to eq("Error retrieving roles from Mediaflux: ERROR")
        researcher.reload
        expect(researcher.developer).to be_falsey
        expect(researcher.sysadmin).to be_falsey
        expect(researcher.trainer).to be_falsey
      end
    end
  end
end
