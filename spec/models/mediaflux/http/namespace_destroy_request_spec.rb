# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mediaflux::Http::NamespaceDestroyRequest, type: :model, connect_to_mediaflux: true do
  let(:valid_project) { FactoryBot.create(:project_with_dynamic_directory, project_id: "10.34770/tbd") }
  let(:sponsor_user) { FactoryBot.create(:project_sponsor) }
  let(:session_id) { sponsor_user.mediaflux_session }
  it "deletes a namespace and everything inside of it" do
    valid_project
    mediaflux_id = ProjectMediaflux.create!(project: valid_project, session_id: session_id)
    expect(mediaflux_id).not_to be_nil
    namespace_list = Mediaflux::Http::NamespaceListRequest.new(session_token: session_id, parent_namespace: "/td-test-001/tigerdataNS").namespaces
    namespace_names = namespace_list.map { |a| a[:name] }
    expect(namespace_names).to include("#{valid_project.directory}NS")
    byebug

    # Destroy the namespace of the project and everything in it
    described_class.new(session_token: session_id, namespace: "/td-test-001/tigerdataNS/Banana1NS").destroy

    namespace_list = Mediaflux::Http::NamespaceListRequest.new(session_token: session_id, parent_namespace: "/td-test-001/tigerdataNS").namespaces
    namespace_names = namespace_list.map { |a| a[:name] }
    expect(namespace_names).not_to include("#{valid_project.directory}NS")
  end
end
#     describe "#new" do
#     before do
#       request_body = <<-XML
# <?xml version=\"1.0\"?>
# <request>
#   <service name=\"asset.namespace.hard.destroy :atomic true :force true :namespace\"
#     <args>
#       <namespace>Pineapple1</namespace>
#     </args>
#   </service>
# </request>
#   XML
#     it "destroys an existing project" do
#       valid_project.directory
#       self.service
#       expect(asset.namespace.exists :namespace valid_project).to eq false
#     end

#     # Specifies the Mediaflux service to use when destroying assets
#     def self.service
#       "asset.namespace.hard.destroy :atomic true :force true :namespace(:valid_project.directory)"
#     end
# end
