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
    let(:updated_csv_file) { Rails.root.join("spec", "fixtures", "files", "updated_user_registration_list.csv") }
    let(:updated_csv_data) do
      CSV.parse(File.read(updated_csv_file), headers: true)
    end
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
    it "updates a name if the name is updated in the spreadsheet" do
      User.load_registration_list
      expect(User.count).to eq 24
      blank_name_user = User.find_by(uid: "munan")
      expect(blank_name_user.family_name).to be_nil
      expect(blank_name_user.display_name).to be_nil
      allow(User).to receive(:csv_data).and_return(updated_csv_data)
      User.load_registration_list
      expect(User.count).to eq 24
      updated_name_user = User.find_by(uid: "munan")
      expect(updated_name_user.family_name).to eq "Nøme"
      expect(updated_name_user.display_name).to eq "Fáké Nøme"
    end
    it "loads the eligible sponsor and manager roles" do
      User.load_registration_list
      sponsor_user = User.first
      expect(sponsor_user.uid).to eq "mjc12"
      expect(sponsor_user.eligible_sponsor).to be_truthy
      expect(sponsor_user.eligible_manager).to be_truthy
      no_role_user = User.find_by(uid: "hc8719")
      expect(no_role_user.eligible_sponsor).to be_falsey
      expect(no_role_user.eligible_manager).to be_falsey
      supervisor_user = User.find_by(uid: "eostrike")
      expect(supervisor_user.eligible_sponsor).to be_truthy
      expect(supervisor_user.eligible_manager).to be_falsey
      manager_user = User.find_by(uid: "cac9")
      expect(manager_user.eligible_sponsor).to be_falsey
      expect(manager_user.eligible_manager).to be_truthy
    end
  end
end
