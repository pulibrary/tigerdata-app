# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrincetonUsers, type: :model do
  describe "#create_users_from_ldap" do
    # this test can not be run on circle (tagged :integration to not run on circle ci)
    it "create the user when connected to the actual ldap (you must be on campus or VPN for this to work)",
       :integration do
      expect { described_class.create_users_from_ldap(current_uid_start: "gsj") }.to change { User.count }.by(1)
      expect(User.last.uid).to eq("gsjobs")
      expect(User.last.display_name).to eq("Graduate School Jobs, ")
      expect(User.last.family_name).to eq("Graduate School Jobs")
      expect(User.last.given_name).to be_blank
    end

    # This test is dangerous on it's own because the results from LDAP could change without us knowing.
    # That said circle ci can not connect to ldap, so this test is for circle.
    # The test above talks directly to LDAP so if things change we should see a failure when we run it locally.
    context "I stub out the connection" do
      let(:entry) { instance_double(Net::LDAP::Entry) }
      let(:connection) { instance_double(Net::LDAP, get_operation_result: status) }
      let(:status) { OpenStruct.new(message: "Success") }

      it "returns creates the user" do
        allow(connection).to receive(:search).with(attributes: [:pudisplayname, :givenname, :sn, :uid, :edupersonprincipalname], filter: anything).and_return([])
        allow(connection).to receive(:search).with(attributes: [:pudisplayname, :givenname, :sn, :uid, :edupersonprincipalname],
                                                   filter: (~ Net::LDAP::Filter.eq("pustatus", "guest")) & Net::LDAP::Filter.eq("uid", "gsjo*")).and_return([entry])
        allow(entry).to receive(:[]).with(:uid).and_return(["gsjobs"])
        allow(entry).to receive(:[]).with(:sn).and_return(["Graduate School Jobs"])
        allow(entry).to receive(:[]).with(:pudisplayname).and_return(["Graduate School Jobs, "])
        allow(entry).to receive(:[]).with(:edupersonprincipalname).and_return(["email@princeton.edu"])
        allow(entry).to receive(:[]).with(:givenname).and_return([])

        expect { described_class.create_users_from_ldap(current_uid_start: "gsj", ldap_connection: connection) }.to change { User.count }.by(1)
        user = User.last
        expect(user.uid).to eq("gsjobs")
        expect(user.display_name).to eq("Graduate School Jobs, ")
        expect(user.family_name).to eq("Graduate School Jobs")
        expect(user.given_name).to be_blank
        expect(user.email).to eq("email@princeton.edu")
        expect(user.provider).to eq("cas")
        PrincetonUsers::CHARS_AND_NUMS.each do |char|
          expect(connection).to have_received(:search).with(attributes: [:pudisplayname, :givenname, :sn, :uid, :edupersonprincipalname],
                                                            filter: (~ Net::LDAP::Filter.eq("pustatus", "guest")) & Net::LDAP::Filter.eq("uid", "gsj#{char}*"))
        end
      end

      it "delves deeper if required" do
        error_status = OpenStruct.new(message: "Error")

        allow(connection).to receive(:get_operation_result).and_return(error_status, status)
        allow(connection).to receive(:search).with(attributes: [:pudisplayname, :givenname, :sn, :uid, :edupersonprincipalname], filter: anything).and_return([])
        allow(connection).to receive(:search).with(attributes: [:pudisplayname, :givenname, :sn, :uid, :edupersonprincipalname],
                                                   filter: (~ Net::LDAP::Filter.eq("pustatus", "guest")) & Net::LDAP::Filter.eq("uid", "gsjo*")).and_return([entry])
        allow(entry).to receive(:[]).with(:uid).and_return(["gsjobs"])
        allow(entry).to receive(:[]).with(:sn).and_return(["Graduate School Jobs"])
        allow(entry).to receive(:[]).with(:pudisplayname).and_return(["Graduate School Jobs, "])
        allow(entry).to receive(:[]).with(:edupersonprincipalname).and_return(["email@princeton.edu"])
        allow(entry).to receive(:[]).with(:givenname).and_return([])

        expect { described_class.create_users_from_ldap(current_uid_start: "gsj", ldap_connection: connection) }.to change { User.count }.by(1)
        expect(User.last.uid).to eq("gsjobs")
        expect(User.last.display_name).to eq("Graduate School Jobs, ")
        expect(User.last.family_name).to eq("Graduate School Jobs")
        expect(User.last.given_name).to be_blank
        expect(User.last.email).to eq("email@princeton.edu")
        PrincetonUsers::CHARS_AND_NUMS.each do |char|
          expect(connection).to have_received(:search).with(attributes: [:pudisplayname, :givenname, :sn, :uid, :edupersonprincipalname],
                                                            filter: (~ Net::LDAP::Filter.eq("pustatus", "guest")) & Net::LDAP::Filter.eq("uid", "gsj#{char}*"))
          expect(connection).to have_received(:search).with(attributes: [:pudisplayname, :givenname, :sn, :uid, :edupersonprincipalname],
                                                            filter: (~ Net::LDAP::Filter.eq("pustatus", "guest")) & Net::LDAP::Filter.eq("uid", "gsja#{char}*"))
        end
      end

      it "skips the user if the email is nil" do
        allow(connection).to receive(:search).with(attributes: [:pudisplayname, :givenname, :sn, :uid, :edupersonprincipalname], filter: anything).and_return([])
        allow(connection).to receive(:search).with(attributes: [:pudisplayname, :givenname, :sn, :uid, :edupersonprincipalname],
                                                   filter: (~ Net::LDAP::Filter.eq("pustatus", "guest")) & Net::LDAP::Filter.eq("uid", "gsjo*")).and_return([entry])
        allow(entry).to receive(:[]).with(:uid).and_return(["gsjobs"])
        allow(entry).to receive(:[]).with(:sn).and_return(["Graduate School Jobs"])
        allow(entry).to receive(:[]).with(:pudisplayname).and_return(["Graduate School Jobs, "])
        allow(entry).to receive(:[]).with(:edupersonprincipalname).and_return([])
        allow(entry).to receive(:[]).with(:givenname).and_return([])

        expect { described_class.create_users_from_ldap(current_uid_start: "gsj", ldap_connection: connection) }
          .to change { User.count }.by(0)
      end
    end
  end

  describe "#user_from_ldap" do
    context "the ldap entry is missing edupersonprincipalname" do
      let(:ldap_person) do
        {
          uid: ["foo"],
          sn: ["Smith"],
          givenname: ["John"],
          pudisplayname: [],
          edupersonprincipalname: []
        }
      end
      it "returns nil" do
        expect(described_class.user_from_ldap(ldap_person)).to be_nil
      end
    end
    context "the ldap entry is missing uid" do
      let(:ldap_person) do
        {
          uid: [],
          sn: ["Smith"],
          givenname: ["John"],
          pudisplayname: ["Smith, John"],
          edupersonprincipalname: ["foo"]
        }
      end
      it "returns nil" do
        expect(described_class.user_from_ldap(ldap_person)).to be_nil
      end
    end

    context "the displayname is blank" do
      let(:empty_ldap_person) do
        {
          uid: ["jsmith"],
          sn: [],
          givenname: [],
          pudisplayname: [],
          edupersonprincipalname: ["email@princeton.edu"]
        }
      end
      let(:updated_ldap_person) do
        {
          uid: ["jsmith"],
          sn: ["Smith"],
          givenname: ["John"],
          pudisplayname: ["Smith, John"],
          edupersonprincipalname: ["email@princeton.edu"]
        }
      end
      it "updates the user with the ldap info" do
        user = described_class.user_from_ldap(empty_ldap_person)
        expect(user.given_name).to be_nil
        expect(user.display_name).to be_nil
        expect(user.family_name).to be_nil
        user = described_class.user_from_ldap(updated_ldap_person)
        expect(user.display_name).to eq("Smith, John")
        expect(user.family_name).to eq("Smith")
        expect(user.given_name).to eq("John")
      end
    end
  end

  describe "#check_for_malformed_ldap_entries" do
    let(:ldap_person) do
      {
        uid: [],
        sn: [],
        givenname: [],
        pudisplayname: [],
        edupersonprincipalname: []
      }
    end
    it "sends an alert to honeybadger so we know how often it is happening" do
      expect(described_class.check_for_malformed_ldap_entries(ldap_person)).to be true
    end
  end

  describe "#load_rdss_developers" do
    context "I am connected to the actual ldap (you must be on campus or VPN for this to work)" do
      it "returns the list of rdss developers" do
        expect(described_class::RDSS_DEVELOPERS).to include("bs3097")
      end

      it "creates users for rdss developers", integration: true do
        expect(User.count).to eq 0
        described_class.load_rdss_developers
        expect(User.count).to eq described_class::RDSS_DEVELOPERS.length
      end
    end

    context "I am not connected to ldap" do
      before do
        allow(described_class).to receive(:create_user_from_ldap_by_uid).and_raise(TigerData::LdapError, "Could not connect to LDAP")
      end
      it "catches and reraises a TigerData::LDAP error to tell the user they are not on VPN" do
        expect { described_class.load_rdss_developers }.to raise_error(TigerData::LdapError, "Unable to create user from LDAP. Are you connected to VPN?")
      end
    end
  end

  describe "#user_list_query" do
    let(:user) { { uid: "sms98", name: "Sotomayor, Asonia", display_name: "Sotomayor, Asonia (sms98)" } }
    let(:user_no_name) { { uid: "sms99", name: nil, display_name: "sms99" } }

    before do
      FactoryBot.create(:user, uid: "sms99", display_name: nil, given_name: nil, family_name: nil)
      FactoryBot.create(:user, uid: "sms98", display_name: "Sotomayor, Asonia")
    end

    it "detect matches by uid" do
      expect(described_class.user_list_query("sms")).to eq [user, user_no_name]
      expect(described_class.user_list_query("ms9")).to eq [user, user_no_name]
      expect(described_class.user_list_query("98")).to eq [user]
      expect(described_class.user_list_query("99")).to eq [user_no_name]
      expect(described_class.user_list_query("abc")).to eq []
    end

    it "detect matches by uid and puts them first" do
      FactoryBot.create(:user, uid: "oto99", display_name: "Anna Smsath", given_name: "Anna", family_name: "Smsath")
      expect(described_class.user_list_query("sms")).to eq [user, user_no_name, { display_name: "Anna Smsath (oto99)", name: "Anna Smsath", uid: "oto99" }]
      expect(described_class.user_list_query("oto")).to eq [{ display_name: "Anna Smsath (oto99)", name: "Anna Smsath", uid: "oto99" }, user]
    end

    it "does not query if no tokens are present" do
      expect(described_class.user_list_query("")).to eq []
    end

    it "detect matches by name, including partial matches out of order" do
      expect(described_class.user_list_query("sonia")).to eq [user]
      expect(described_class.user_list_query("sotomayor")).to eq [user]
      expect(described_class.user_list_query("son soto")).to eq [user]
      expect(described_class.user_list_query("soto son")).to eq [user]
      expect(described_class.user_list_query("sotomayor abc")).to eq []
    end

    it "detect matches by uid and name" do
      expect(described_class.user_list_query("sms soto")).to eq [user]
      expect(described_class.user_list_query("sms jill")).to eq []
    end
  end
end
