# frozen_string_literal: true
require "rails_helper"

RSpec.describe User, type: :model do
  let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "who", extra: { mail: "who@princeton.edu" }) }

  describe "#from_cas" do
    it "returns a user object" do
      user = described_class.from_cas(access_token)
      expect(user).to be_a described_class
    end
  end
end
