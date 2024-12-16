# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::CollectionListRequest, connect_to_mediaflux: true, type: :model do
  subject(:request) { described_class.new(session_token: user.mediaflux_session) }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }

  describe "#resolve" do
    it "retrieves the listing of collections within the default namespace" do
      response = request.resolve
      expect(response.body).not_to be_nil
    end
  end
end
