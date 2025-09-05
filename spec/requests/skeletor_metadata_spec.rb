# frozen_string_literal: true

require "rails_helper"
require "open-uri"

RSpec.describe "The Skeletor Metadata", connect_to_mediaflux: true, metadata: true do
  context "retrieves xml for a project" do
  let(:current_sysadmin) { FactoryBot.create(:sysadmin, uid: "sys123", mediaflux_session: SystemUser.mediaflux_session) }
    it "provides the xml metadata for a project" do
        get project_show_mediaflux_url(project), params: { format: :xml }
        expect(response.code).to eq "200"
        expect(response.content_type).to match "xml"
    end
  end
end
