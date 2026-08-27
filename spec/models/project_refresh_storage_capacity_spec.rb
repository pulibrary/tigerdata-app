# frozen_string_literal: true
require "rails_helper"

RSpec.describe Project, "#refresh_storage_capacity_from_mediaflux!" do
  let!(:sponsor_and_data_manager) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester") }
  let(:stale_capacity) do
    { size: { requested: 500_000.0, approved: 500_000.0 }, unit: { requested: "GB", approved: "GB" } }.with_indifferent_access
  end
  let(:project) do
    FactoryBot.create(
      :project,
      mediaflux_id: 42,
      data_sponsor: sponsor_and_data_manager.uid,
      data_manager: sponsor_and_data_manager.uid,
      storage_capacity: stale_capacity
    )
  end
  let(:quota_info) do
    {
      quota_allocation: 850_000_000_000_000,
      quota_allocation_human: "850 TB",
      quota_used: 1,
      quota_used_human: "1 GB",
      project_files: 1,
      project_files_human: "1 GB",
      recycle_bin: 0,
      recycle_bin_human: "0 bytes",
      old_versions: 0,
      old_versions_human: "0 bytes"
    }
  end

  before do
    quota_request = instance_double(Mediaflux::ProjectQuotaRequest, quota: quota_info)
    allow(Mediaflux::ProjectQuotaRequest).to receive(:new)
      .with(session_token: "mf-session", asset_id: project.mediaflux_id)
      .and_return(quota_request)
  end

  it "writes the Mediaflux human quota into approved portal JSON and keeps requested values" do
    returned = project.refresh_storage_capacity_from_mediaflux!(session_id: "mf-session")
    expect(returned).to eq(quota_info)

    project.reload
    capacity = project.metadata_json["storage_capacity"]
    expect(capacity["size"]["approved"]).to eq(850)
    expect(capacity["unit"]["approved"]).to eq("TB")
    expect(capacity["size"]["requested"]).to eq(500_000.0)
    expect(capacity["unit"]["requested"]).to eq("GB")
  end

  it "raises when the project is not in Mediaflux" do
    project.update!(mediaflux_id: nil)
    expect do
      project.refresh_storage_capacity_from_mediaflux!(session_id: "mf-session")
    end.to raise_error(Project::MediafluxError, /no Mediaflux id/)
  end

  it "raises when Mediaflux does not return a parseable allocation" do
    allow(Mediaflux::ProjectQuotaRequest).to receive(:new)
      .and_return(instance_double(Mediaflux::ProjectQuotaRequest, quota: quota_info.merge(quota_allocation_human: "")))
    expect do
      project.refresh_storage_capacity_from_mediaflux!(session_id: "mf-session")
    end.to raise_error(Project::MediafluxError, /Unable to parse/)
  end
end
