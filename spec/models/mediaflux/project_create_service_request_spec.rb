# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mediaflux::ProjectCreateServiceRequest, type: :model do
  describe "Mediaflux project creation", connect_to_mediaflux: true do
    let!(:user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
    let(:project1) { FactoryBot.create(:approved_project) }
    let(:mpcsr) { Mediaflux::ProjectCreateServiceRequest.new(session_token: user.mediaflux_session, project: project1, token: nil) }

    it "can be instantiated" do
      expect(mpcsr).to be_instance_of Mediaflux::ProjectCreateServiceRequest
    end

    it "can be resolved" do
      expect(mpcsr.resolved?).to eq false
      mpcsr.resolve
      expect(mpcsr.resolved?).to eq true
    end

    # When Mediaflux creates a project, it returns an xml snippet with the Mediaflux id.
    # If the id is an integer, it is valid. If the id is anything else, then forcing it
    # to be an integer will return zero.
    it "parses an id number", integration: true do
      expect(mpcsr.mediaflux_id.to_i).not_to eq 0
    end
  end

  describe "security-level" do
    # Build, do not save. Saving runs ProjectValidator, which requires the
    # factory netid tigerdatatester to exist. These examples only read metadata.
    let(:project) { FactoryBot.build(:approved_project, data_security_level: level) }
    let(:request) { described_class.new(session_token: "token", project: project) }

    context "when the sponsor chose Level 0 - Public" do
      let(:level) { 0 }

      it "sends 0" do
        xml = Nokogiri::XML(request.xml_payload)
        expect(xml.at_xpath("//security-level").text).to eq("0")
      end
    end

    context "when the sponsor chose Level 1 - Internal" do
      let(:level) { 1 }

      it "sends 1" do
        xml = Nokogiri::XML(request.xml_payload)
        expect(xml.at_xpath("//security-level").text).to eq("1")
      end
    end

    context "when no level was chosen" do
      let(:level) { nil }

      it "refuses to build the create request" do
        expect { request }.to raise_error(ArgumentError, /requires security-level/)
      end
    end
  end
end
