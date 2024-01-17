# frozen_string_literal: true
require "rails_helper"

RSpec.describe User, type: :model do
  let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "who", extra: { mail: "who@princeton.edu", givenname: "guess", sn: "who", pudisplayname: "Guess Who?" }) }
  let(:access_token2) { OmniAuth::AuthHash.new(provider: "cas", uid: "who2", extra: { mail: "who2@princeton.edu" }) }
  let(:access_token3) { OmniAuth::AuthHash.new(provider: "cas", uid: "who3", extra: { mail: "who3@princeton.edu", givenname: "", sn: "", pudisplayname: "" }) }
  describe "#from_cas" do
    it "returns a user object" do
      user = described_class.from_cas(access_token)
      expect(user).to be_a described_class
      expect(user.uid).to eq("who")
      expect(user.given_name).to eq("guess")
      expect(user.family_name).to eq("who")
      expect(user.display_name).to eq("Guess Who?")
    end
  end
  describe "#display name safe" do
    it "testing a full name" do
      user = described_class.from_cas(access_token)
      expect(user).to be_a described_class
      expect(user.uid).to eq("who")
      expect(user.given_name).to eq("guess")
      expect(user.family_name).to eq("who")
      expect(user.display_name_safe).to eq("Guess Who")
    end
    it "testing a uid" do
      user = described_class.from_cas(access_token2)
      expect(user).to be_a described_class
      expect(user.uid).to eq("who2")
      expect(user.display_name_safe).to eq("who2")
    end
    it "testing a empty given name" do
      user = described_class.from_cas(access_token3)
      expect(user).to be_a described_class
      expect(user.uid).to eq("who3")
      expect(user.display_name_safe).to eq("who3")
    end
  end
end
