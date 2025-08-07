# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::NamespaceDestroyRequest, type: :model, connect_to_mediaflux: true do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:valid_project) { FactoryBot.create(:project_with_dynamic_directory, project_id: random_project_id) }
  let(:namespace) { valid_project.project_directory.split("/").last + "NS" }
  let(:sponsor_user) { FactoryBot.create(:project_sponsor, mediaflux_session: SystemUser.mediaflux_session) }
  let(:session_id) { sponsor_user.mediaflux_session }
  context "when a namespace exists" do
    it "deletes a namespace and everything inside of it",
    :integration do
      mediaflux_id = valid_project.approve!(current_user: sponsor_user)
      expect(mediaflux_id).not_to be_nil
      parent_namespace = "princeton/" + valid_project.project_directory.split("/")[0..-2].map { |token| token + "NS" }.join("/")
      namespace_list = ::Mediaflux::NamespaceListRequest.new(session_token: session_id, parent_namespace: ).namespaces
      namespace_names = namespace_list.pluck(:name)
      expect(namespace_names).to include(namespace)

      # Destroy the namespace of the project and everything in it
      described_class.new(session_token: session_id, namespace: "#{parent_namespace}/#{namespace}").destroy
      namespace_list = Mediaflux::NamespaceListRequest.new(session_token: session_id, parent_namespace: ).namespaces
      namespace_names = namespace_list.pluck(:name)
      expect(namespace_names).not_to include(namespace)

      # Should raise an error when attempting to destroy a namespace that does not exist
      expect { described_class.new(session_token: session_id, namespace: "#{parent_namespace}/#{namespace}").destroy }.to raise_error do |error|
        expect(error).to be_a(StandardError)
        expect(error.message).to include("call to service 'asset.namespace.hard.destroy' failed: The namespace #{parent_namespace}/#{namespace} does not exist or is not accessible")
      end
    end
  end
end
