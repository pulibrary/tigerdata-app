# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectMediaflux, type: :model do
  let(:project) do
    request = FactoryBot.create(:request_project)
    request.number_of_files = "Between 100,000 and 1,000,000"
    request.hpc = "Yes"
    request.smb = "Yes"
    request.globus = "Yes"
    request.project_purpose = "administrative"
    request.approve(sponsor_and_data_manager_user)
  end

  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }

  describe "#xml_payload" do
    let(:project_not_in_mediaflux) { FactoryBot.create(:project_with_doi) }

    it "raises errors when project is not accessible", :integration do
      # The project is not in mediaflux and therefore this will raise an exception
      expect { described_class.xml_payload(project: project_not_in_mediaflux, user: sponsor_and_data_manager_user) }.to raise_error(StandardError)
    end
  end
end
