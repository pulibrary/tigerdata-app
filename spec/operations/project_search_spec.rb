# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProjectSearch, type: :operation, integration: true do
  let!(:approver) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }

  let(:request1) { FactoryBot.create(:request_project, project_title: "soda pop") }
  let(:request2) { FactoryBot.create(:request_project, project_title: "orange pop") }

  # TODO: The below line will actually create a title with a quote in it (well actually `\"`) and that can be searched for like a single quote
  #       The issue is the project can not be activated because the title in mediaflux is `grape soda < > ' \"` and the local title is the one below
  # let(:request3) { FactoryBot.create(:request_project, project_title: "grape soda < > ' \\\\\\\\\\\\\\\"") }
  let(:request3) { FactoryBot.create(:request_project, project_title: "z grape soda < ' > \\ ") }
  let!(:project1) { create_project_in_mediaflux(request: request1, current_user: approver) }
  let!(:project2) { create_project_in_mediaflux(request: request2, current_user: approver) }
  let!(:project3) { create_project_in_mediaflux(request: request3, current_user: approver) }

  after do
    Mediaflux::AssetDestroyRequest.new(session_token: approver.mediaflux_session, collection: project1.mediaflux_id, members: true).resolve
    Mediaflux::AssetDestroyRequest.new(session_token: approver.mediaflux_session, collection: project2.mediaflux_id, members: true).resolve
    Mediaflux::AssetDestroyRequest.new(session_token: approver.mediaflux_session, collection: project3.mediaflux_id, members: true).resolve
  end

  describe "#call" do
    context "Success case" do
      it "finds projects" do
        result = described_class.new.call(search_string: "*pop", requestor: approver)
        expect(result).to be_success
        projects = result.value!
        expect(projects.map(&:id)).to include(project1.id)
        expect(projects.map(&:id)).to include(project2.id)
        expect(projects.map(&:id)).not_to include(project3.id)
      end

      it "returns an empty array if there is no data" do
        result = described_class.new.call(search_string: "blah", requestor: approver)
        expect(result).to be_success
        projects = result.value!
        expect(projects).to eq([])
      end

      it "searches for double quote just fine if you escape it twice" do
        # TODO: We can not create a project with a quote in the title at this point, but if we could the query below would work in mediaflux
        # asset.query :where xpath(tigerdata:project/Title) matches ignore-case 'z grape*\"*'
        pending "There is a title miss match on activate that needs to be fixed"
        result = described_class.new.call(search_string: "z grape*\\\\\"*", requestor: approver)
        expect(result).to be_success
        expect(result.value!).to eq([project3])
      end

      it "searches for single quote just fine if you escape it" do
        result = described_class.new.call(search_string: "z grape*\\'*", requestor: approver)
        expect(result).to be_success
        expect(result.value!).to eq([project3])
      end

      it "searches for greater than just fine" do
        result = described_class.new.call(search_string: "z grape*>*", requestor: approver)
        expect(result).to be_success
        expect(result.value!).to eq([project3])
      end

      it "searches for less than just fine" do
        result = described_class.new.call(search_string: "z grape*<*", requestor: approver)
        expect(result).to be_success
        expect(result.value!).to eq([project3])
      end

      it "searches for back slash just fine" do
        result = described_class.new.call(search_string: "z grape*\\\\*", requestor: approver)
        expect(result).to be_success
        expect(result.value!).to eq([project3])
      end
    end
  end
  context "Failure cases" do
    it "returns a failure if the search is blank" do
      result = described_class.new.call(search_string: "", requestor: approver)
      expect(result).not_to be_success
      error_message = result.failure
      expect(error_message).to include("Search String cannot be empty")
    end

    it "returns a failure if one of the projects do not match up" do
      project1.destroy # make sure the project is not on the rails side
      result = described_class.new.call(search_string: "*pop", requestor: approver)
      expect(result).not_to be_success
      error_message = result.failure
      expect(error_message).to include("The following Mediaflux Projects were not found in the Rails database: #{project1.mediaflux_id}")
    end

    it "returns a failure if the search query has bad characters" do
      result = described_class.new.call(search_string: "\"'blah", requestor: approver)
      expect(result).not_to be_success
      error_message = result.failure
      expect(error_message).to include("Error querying mediaflux: call to service 'asset.query' failed")
    end
  end
end
