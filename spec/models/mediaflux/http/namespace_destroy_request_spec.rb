# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::NamespaceDestroyRequest, type: :model, connect_to_mediaflux: true do
  let(:valid_project) { FactoryBot.create(:project_with_dynamic_directory, project_id: "10.34770/tbd") }
  let(:namespace) { "#{valid_project.project_directory_short}NS".strip.gsub(/[^A-Za-z\d]/, "-") }
  let(:sponsor_user) { FactoryBot.create(:project_sponsor) }
  let(:session_id) { sponsor_user.mediaflux_session }
  it "deletes a namespace and everything inside of it" do
    mediaflux_id = valid_project.save_in_mediaflux(session_id: session_id)
    expect(mediaflux_id).not_to be_nil
    namespace_list = Mediaflux::Http::NamespaceListRequest.new(session_token: session_id, parent_namespace: "/td-test-001/tigerdataNS").namespaces
    namespace_names = namespace_list.pluck(:name)
    expect(namespace_names).to include(namespace)

    # Destroy the namespace of the project and everything in it
    described_class.new(session_token: session_id, namespace: "/td-test-001/tigerdataNS/#{namespace}").destroy
    namespace_list = Mediaflux::Http::NamespaceListRequest.new(session_token: session_id, parent_namespace: "/td-test-001/tigerdataNS").namespaces
    namespace_names = namespace_list.pluck(:name)
    expect(namespace_names).not_to include(namespace)
    response = described_class.new(session_token: session_id, namespace: "/td-test-001/tigerdataNS/#{namespace}").destroy
    expect(response[:message]).to include("The namespace '/td-test-001/tigerdataNS/#{namespace}' does not exist or is not accessible")
  end
end
