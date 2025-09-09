# frozen_string_literal: true

require "rails_helper"

RSpec.describe "The Skeletor Metadata", connect_to_mediaflux: true, metadata: true, type: :request do
  let(:data_manager) { FactoryBot.create(:data_manager, uid: "pp9425", mediaflux_session: SystemUser.mediaflux_session) }
  let(:data_sponsor) { FactoryBot.create(:project_sponsor, uid: "rl3667", mediaflux_session: SystemUser.mediaflux_session) }
  let(:project) { FactoryBot.create(:approved_project, data_manager: data_manager.uid, data_sponsor: data_sponsor.uid) }

  context "retrieves xml for a project" do
    before do
      sign_in data_manager
    end

    it "provides the xml metadata for a project" do
      get project_url(project), params: { format: :xml }
      expect(response.content_type).to match "xml"
      expect(response.code).to eq "200"
      xml = response.parsed_body
      xml_doc = Nokogiri::XML(xml)
      expect(xml_doc.xpath("//title/text()").to_s).to eq project.title
    end
  end
end
