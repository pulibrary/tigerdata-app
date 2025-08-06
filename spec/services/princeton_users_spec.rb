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
  describe "#load_rdss_developers" do
    it "returns the list of rdss developers" do
      expect(described_class::RDSS_DEVELOPERS).to include("bs3097")
    end

    it "creates users for rdss developers", integration: true do
      expect(User.count).to eq 0
      described_class.load_rdss_developers
      expect(User.count).to eq described_class::RDSS_DEVELOPERS.length
    end
  end
end
