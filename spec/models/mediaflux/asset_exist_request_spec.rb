# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::AssetExistRequest, type: :model, connect_to_mediaflux: true do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:session_token) { Mediaflux::LogonRequest.new.session_token }
  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:project) { FactoryBot.build :project_with_doi }

  before do
    project.approve!(current_user: user)
  end

  describe "#exist" do
    it "validates that an asset exist or not", :integration do
      valid_path = "princeton/#{project.metadata_model.project_directory}"
      subject = described_class.new(session_token: session_token, path: valid_path)
      expect(subject.exist?).to be true

      nonexisting_path = "princeton/#{project.metadata_model.project_directory}-nope"
      subject = described_class.new(session_token: session_token, path: nonexisting_path)
      expect(subject.exist?).to be false

      non_existing_namespace = "princeton-non-existing/#{project.metadata_model.project_directory}"
      subject = described_class.new(session_token: session_token, path: non_existing_namespace)
      expect(subject.exist?).to be false
    end
  end
end
