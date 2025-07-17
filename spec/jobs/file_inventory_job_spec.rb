# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileInventoryJob, connect_to_mediaflux: true do
  include ActiveJob::TestHelper

  let(:user) { FactoryBot.create(:user, mediaflux_session: SystemUser.mediaflux_session) }
  let(:project_in_mediaflux) { FactoryBot.create(:project_with_doi) }

  before do
    ProjectMediaflux.create!(user: user, project: project_in_mediaflux)
  end

  describe "#perform_later" do
    it "creates a file inventory request attached to the user and the project" do
      expect(FileInventoryRequest.count).to be 0
      perform_enqueued_jobs do
        FileInventoryJob.perform_later(user_id: user.id, project_id: project_in_mediaflux.id, mediaflux_session: user.mediaflux_session)
      end
      expect(FileInventoryRequest.count).to be 1
      file_inventory_request = FileInventoryRequest.first
      expect(file_inventory_request.state).to eq UserRequest::COMPLETED
    end
  end

  describe "#perform_now" do
    # let(:file_inventory_job) { described_class.perform_now(user_id:, project_id:) }
    it "creates a file inventory request attached to the user and the project" do
      expect(FileInventoryRequest.count).to be 0
      FileInventoryJob.perform_now(user_id: user.id, project_id: project_in_mediaflux.id, mediaflux_session: user.mediaflux_session)
      expect(FileInventoryRequest.count).to be 1
      file_inventory_request = FileInventoryRequest.first
      expect(file_inventory_request.state).to eq UserRequest::COMPLETED
    end

    it "saves the output to a file" do
      file_inventory_request = described_class.perform_now(user_id: user.id, project_id: project_in_mediaflux.id, mediaflux_session: user.mediaflux_session)
      output_file = Pathname.new(Rails.configuration.mediaflux["shared_files_location"]).join("#{file_inventory_request.job_id}.csv").to_s
      expect(File.exist?(output_file)).to be true
    end

    it "puts the file path into the file inventory request" do
      file_inventory_request = described_class.perform_now(user_id: user.id, project_id: project_in_mediaflux.id, mediaflux_session: user.mediaflux_session)
      output_file = Pathname.new(Rails.configuration.mediaflux["shared_files_location"]).join("#{file_inventory_request.job_id}.csv").to_s
      file_inventory_request = FileInventoryRequest.first
      expect(file_inventory_request.output_file).to eq(output_file)
    end

    it "puts the title into the file inventory request" do
      described_class.perform_now(user_id: user.id, project_id: project_in_mediaflux.id, mediaflux_session: user.mediaflux_session)
      file_inventory_request = FileInventoryRequest.first
      expect(file_inventory_request.request_details["project_title"]).to eq(project_in_mediaflux.title)
    end

    it "puts the completion time into the file inventory request" do
      described_class.perform_now(user_id: user.id, project_id: project_in_mediaflux.id, mediaflux_session: user.mediaflux_session)
      file_inventory_request = FileInventoryRequest.first
      expect(file_inventory_request.completion_time).to be_instance_of(ActiveSupport::TimeWithZone)
    end

    context "when an invalid User ID is specified" do
      it "raises an error" do
        expect do
          described_class.perform_now(user_id: "invalid-id", project_id: project_in_mediaflux.id, mediaflux_session: user.mediaflux_session)
        end.to raise_error(ActiveRecord::RecordNotFound, /Couldn't find User/)
      end
    end

    context "when an ActiveRecord::StatementInvalid error occurs" do
      before do
        @error_count = 0
        allow_any_instance_of(FileInventoryRequest).to receive(:update).and_wrap_original do |original_method, *args|
          if @error_count == 0
            # Force an error the first time to make sure the retry is invoked in the code
            @error_count = 1
            raise ActiveRecord::StatementInvalid, "error"
          else
            original_method.call(*args)
          end
        end
      end

      it "it handles the retry for ActiveRecord::StatementInvalid exception" do
        described_class.perform_now(user_id: user.id, project_id: project_in_mediaflux.id, mediaflux_session: user.mediaflux_session)
        file_inventory_request = FileInventoryRequest.first
        expect(file_inventory_request.state).to eq "completed"
      end
    end
  end
end
