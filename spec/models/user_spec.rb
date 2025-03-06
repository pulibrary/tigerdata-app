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
    it "returns nil if the user does not exist" do
      expect(described_class.from_cas(access_token)).to be_nil
    end

    it "returns a user object if the user exists" do
      original_user = FactoryBot.create(:user, uid: "who")
      user = described_class.from_cas(access_token)
      expect(user).to be_a described_class
      expect(user.uid).to eq("who")
      expect(user.given_name).to eq(original_user.given_name)
      expect(user.family_name).to eq(original_user.family_name)
      expect(user.display_name).to eq(original_user.display_name)
    end

    it "returns a user object if the user exists and sets the name information if given name is empty" do
      FactoryBot.create(:user, uid: "who", given_name: nil)
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
      FactoryBot.create(:user, uid: "who", given_name: nil)
      user = described_class.from_cas(access_token)
      expect(user).to be_a described_class
      expect(user.uid).to eq("who")
      expect(user.given_name).to eq("guess")
      expect(user.family_name).to eq("who")
      expect(user.display_name_safe).to eq("Guess Who?")
    end
    it "testing a uid" do
      FactoryBot.create(:user, uid: "who2", given_name: nil)
      user = described_class.from_cas(access_token2)
      expect(user).to be_a described_class
      expect(user.uid).to eq("who2")
      expect(user.display_name_safe).to eq("who2")
    end
    it "testing a empty given name" do
      FactoryBot.create(:user, uid: "who3", given_name: nil)
      user = described_class.from_cas(access_token3)
      expect(user).to be_a described_class
      expect(user.uid).to eq("who3")
      expect(user.display_name_safe).to eq("who3")
    end
    it "testing a last name with distinct capitaliztion" do
      FactoryBot.create(:user, uid: "who4", given_name: nil)
      user = described_class.from_cas(access_token4)
      expect(user).to be_a described_class
      expect(user.uid).to eq("who4")
      expect(user.display_name_safe).to eq("Guess McWho")
    end
    it "testing a last name with hyphen" do
      FactoryBot.create(:user, uid: "who5", given_name: nil)
      user = described_class.from_cas(access_token5)
      expect(user).to be_a described_class
      expect(user.uid).to eq("who5")
      expect(user.display_name_safe).to eq("Guess Who-You")
    end
    it "testing a last name with quote" do
      FactoryBot.create(:user, uid: "who6", given_name: nil)
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
      expect(User.count).to eq 192
    end
    it "does not create a user if they exist already" do
      User.create(uid: "mjc12", family_name: "Chandler", display_name: "Matt Chandler", email: "mjc12@princeton.edu")
      expect(User.count).to eq 1
      User.load_registration_list
      expect(User.count).to eq 192
      user = User.find_by(uid: "mjc12")
      # If we don't say that this is a cas user, they won't be able to log in with CAS
      expect(user.provider).to eq "cas"
    end
    it "updates a name if the name is updated in the spreadsheet" do
      User.load_registration_list
      expect(User.count).to eq 192
      blank_name_user = User.find_by(uid: "munan")
      expect(blank_name_user.family_name).to be_nil
      expect(blank_name_user.display_name).to be_nil
      allow(User).to receive(:csv_data).and_return(updated_csv_data)
      User.load_registration_list
      expect(User.count).to eq 192
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

    it "loads the sysadmin and superuser roles" do
      User.load_registration_list
      super_user = User.find_by(uid: "cac9")
      expect(super_user.superuser).to be_truthy
      expect(super_user.sysadmin).to be_falsey
      sysadmin_user = User.find_by(uid: "cbentler")
      expect(sysadmin_user.superuser).to be_falsey
      expect(sysadmin_user.sysadmin).to be_truthy
      other_user = User.find_by(uid: "munan")
      expect(other_user.superuser).to be_falsey
      expect(other_user.sysadmin).to be_falsey
    end
    it "loads users with the trainer role" do
      User.load_registration_list
      user = User.find_by(uid: "mjc12")
      expect(user.trainer).to be_truthy
      expect(user.trainer?).to be_truthy
      other_user = User.find_by(uid: "eparham")
      expect(other_user.trainer).to be_falsey
      expect(other_user.trainer?).to be_falsey
    end
  end

  context "Devise Methods" do
    it "serializes and deserialize users" do
      user = FactoryBot.create(:user, uid: "pul1234", given_name: nil)
      expect(User.serialize_into_session(user)).to eq ["pul1234", ""]
      expect(User.serialize_from_session("pul1234", "").uid).to eq "pul1234"
      expect(User.serialize_from_session("nope", "")).to be nil
    end
  end

  describe "#eligible_sponsor?" do
    it "should be true for a sponsor" do
      user = FactoryBot.create(:project_sponsor)
      expect(user).to be_eligible_sponsor
    end

    it "should be true for a superuser" do
      user = FactoryBot.create(:superuser)
      expect(user).to be_eligible_sponsor
    end
  end

  describe "#eligible_manager?" do
    it "should be true for a manager" do
      user = FactoryBot.create(:data_manager)
      expect(user).to be_eligible_manager
    end

    it "should be true for a superuser" do
      user = FactoryBot.create(:superuser)
      expect(user).to be_eligible_manager
    end
  end

  describe "#sponsor_users" do
    it "should only show sponsers" do
      FactoryBot.create(:superuser)
      project_sponsor = FactoryBot.create(:project_sponsor)
      FactoryBot.create(:user)
      expect(User.sponsor_users.map(&:uid)).to eq([project_sponsor.uid])
    end

    context "in development" do
      it "should only show sponsers and superusers" do
        superuser = FactoryBot.create(:superuser)
        project_sponsor = FactoryBot.create(:project_sponsor)
        FactoryBot.create(:user)
        allow(Rails.env).to receive(:development?).and_return true
        expect(User.sponsor_users.map(&:uid).sort).to eq([superuser.uid, project_sponsor.uid].sort)
      end
    end
  end

  describe "#eligible_sysadmin?" do
    it "should be true for a sysadmin" do
      user = FactoryBot.create(:sysadmin)
      expect(user).to be_eligible_sysadmin
    end

    it "should be true for a superuser" do
      user = FactoryBot.create(:superuser)
      expect(user).to be_eligible_sysadmin
    end
  end

  describe "#eligible_to_create_new?" do
    it "should be true for a sysadmin" do
      user = FactoryBot.create(:sysadmin)
      expect(user).to be_eligible_to_create_new
    end

    it "should be true for a superuser" do
      user = FactoryBot.create(:superuser)
      expect(user).to be_eligible_to_create_new
    end

    it "should be true for a sponsor who is a trainer" do
      user = FactoryBot.create(:project_sponsor, trainer: true)
      expect(user).to be_eligible_to_create_new
    end

    it "should be false for a manager" do
      user = FactoryBot.create(:data_manager)
      expect(user).not_to be_eligible_to_create_new
    end

    it "should be false for a sponsor" do
      user = FactoryBot.create(:project_sponsor)
      expect(user).not_to be_eligible_to_create_new
    end

    it "should be false for a data user" do
      user = FactoryBot.create(:user)
      expect(user).not_to be_eligible_to_create_new
    end
  end

  describe "#mediaflux_from_session" do
    let(:user) { described_class.new }
    before do
      allow(SystemUser).to receive(:mediaflux_session).and_return("192system")
    end
    it "loads the mediaflux session from the system user" do
      expect(user.mediaflux_from_session({})).to eq("192system")
      expect(user.mediaflux_session).to eq("192system")
    end

    it "loads the mediaflux session from the session when present" do
      expect(user.mediaflux_from_session({ mediaflux_session: "222session" })).to eq("222session")
      expect(user.mediaflux_session).to eq("222session")
    end
  end
end
