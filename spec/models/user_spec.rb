# frozen_string_literal: true
require "rails_helper"

RSpec.describe User, type: :model do
  let(:access_token) { OmniAuth::AuthHash.new(provider: "cas", uid: "who", extra: { mail: "who@princeton.edu", givenname: "guess", sn: "who", pudisplayname: "Guess Who?" }) }
  let(:access_token2) { OmniAuth::AuthHash.new(provider: "cas", uid: "who2", extra: { mail: "who2@princeton.edu" }) }
  let(:access_token3) { OmniAuth::AuthHash.new(provider: "cas", uid: "who3", extra: { mail: "who3@princeton.edu", givenname: "", sn: "", pudisplayname: "" }) }
  let(:access_token4) { OmniAuth::AuthHash.new(provider: "cas", uid: "who4", extra: { mail: "who4@princeton.edu", givenname: "Guess", sn: "McWho", pudisplayname: "Guess McWho" }) }
  let(:access_token5) { OmniAuth::AuthHash.new(provider: "cas", uid: "who5", extra: { mail: "who5@princeton.edu", givenname: "Guess", sn: "Who-You", pudisplayname: "Guess Who-You" }) }
  let(:access_token6) { OmniAuth::AuthHash.new(provider: "cas", uid: "who6", extra: { mail: "who6@princeton.edu", givenname: "Guess", sn: "Y'Who", pudisplayname: "Guess Y'Who" }) }
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
      expect(user.display_name_safe).to eq("Guess Who?")
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
    it "testing a last name with distinct capitaliztion" do
      user = described_class.from_cas(access_token4)
      expect(user).to be_a described_class
      expect(user.uid).to eq("who4")
      expect(user.display_name_safe).to eq("Guess McWho")
    end
    it "testing a last name with hyphen" do
      user = described_class.from_cas(access_token5)
      expect(user).to be_a described_class
      expect(user.uid).to eq("who5")
      expect(user.display_name_safe).to eq("Guess Who-You")
    end
    it "testing a last name with quote" do
      user = described_class.from_cas(access_token6)
      expect(user).to be_a described_class
      expect(user.uid).to eq("who6")
      expect(user.display_name_safe).to eq("Guess Y'Who")
    end
  end
  context "loading Registration List" do
    it "creates a new user for every line in the file" do
      expect(User.count).to eq 0
      User.load_registration_list
      expect(User.count).to eq 24
    end
    it "does not create a user if they exist already" do
      User.create(uid: "mjc12", family_name: "Chandler", display_name: "Matt Chandler", email: "mjc12@princeton.edu")
      expect(User.count).to eq 1
      User.load_registration_list
      expect(User.count).to eq 24
    end
  end
end
