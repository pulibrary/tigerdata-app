# frozen_string_literal: true
require "rails_helper"

# This is only here to prove that we can use a mediaflux service that is provided by
# a java plugin.
RSpec.describe Mediaflux::StringReverse, connect_to_mediaflux: true, type: :model do
  subject(:request) { described_class.new(string: string_to_reverse, session_token: session_token) }
  let(:session_token) { user.mediaflux_session }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:string_to_reverse) { "Hello, Mediaflux!" }

  describe "#resolve" do
    it "reverses a string using a service provided by mediaflux" do
      request.resolve
      expect(request.response_body).to match(/!xulfaideM ,olleH/)
    end
  end
end
