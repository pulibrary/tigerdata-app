# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::PackageDescribeRequest, connect_to_mediaflux: true, type: :model do
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }

  describe "#describe" do
    it "returns the version information" do
      # A well-known existing package
      request = described_class.new(session_token: user.mediaflux_session, package_name: "tigerdata-plugin")
      expect(request.error?).to be false
      expect(request.describe[:version] >= "0.0.2").to be true

      # A non-existing existing package
      request = described_class.new(session_token: user.mediaflux_session, package_name: "blah-blah-blah-tigerdata")
      expect(request.error?).to be true
      expect(request.describe[:version]).to eq ""
    end
  end
end
