# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrincetonUsers, type: :model do
  describe "#create_users_from_ldap" do
    # this test can not be run on circle (tagged :no_ci to not run on circle ci)
    it "create the user when connected to the actual ldap (you must be on campus or VPN for this to work)",
       :no_ci do
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
        expect(User.last.uid).to eq("gsjobs")
        expect(User.last.display_name).to eq("Graduate School Jobs, ")
        expect(User.last.family_name).to eq("Graduate School Jobs")
        expect(User.last.given_name).to be_blank
        expect(User.last.email).to eq("email@princeton.edu")
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
    end
  end
end
