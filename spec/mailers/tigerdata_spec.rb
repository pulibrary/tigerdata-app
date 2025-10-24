# frozen_string_literal: true
require "rails_helper"

RSpec.describe TigerdataMailer, type: :mailer do
  let!(:sponsor_and_data_manager_user) { FactoryBot.create(:sponsor_and_data_manager, uid: "tigerdatatester", mediaflux_session: SystemUser.mediaflux_session) }
  let(:project) { FactoryBot.create :project, project_id: "abc123/def" , mediaflux_id: 123}
  let(:project_id) { project.id }

  let(:valid_request) do
    Request.create(
      project_title: "Valid Request", 
      data_sponsor: sponsor_and_data_manager_user.uid, 
      data_manager: sponsor_and_data_manager_user.uid, 
      departments: ["RDSS"],
      quota: "500 GB", 
      description: "A valid request",
      project_folder: "valid_folder",
      user_roles: [
        { uid: "abc123", name: "Abe Cat" }, 
        { uid: "ddd", name: "Dandy Dog", read_only: true },
        { uid: "efg", name: "Fern Frog", read_only: false }
      ]
    )
  end
  let(:request_id) { valid_request.id }

context "When a project is created" do

  it "Sends project creation requests" do
    expect { described_class.with(project_id:, approver: sponsor_and_data_manager_user).project_creation.deliver }.to change { ActionMailer::Base.deliveries.count }.by(1)
    mail = ActionMailer::Base.deliveries.last

    expect(mail.subject).to eq ("Project: '#{project.title}' has been approved")
    expect(mail.to).to eq [sponsor_and_data_manager_user.email]
    expect(mail.cc).to eq ["test_to@example.com"]
    expect(mail.from).to eq ["no-reply@princeton.edu"]

    html_body = mail.html_part.body.to_s
    expect(html_body).not_to be_empty
    expect(html_body).to have_content(project.id)

    expect(html_body).to have_content(project.mediaflux_id)
    expect(html_body).to have_content(project.title)
    expect(html_body).to have_content(project.project_directory)
    expect(html_body).to have_content(project.metadata_json["data_sponsor"])
    expect(html_body).to have_content(project.metadata_json["data_manager"])

    expect(html_body).to include("The following project has been approved and created:")
    expect(html_body).to include("For more details, see #{project_url(project)}")
  end

  context "when the project ID is invalid or nil" do
    let(:project_id) { "invalid" }

    it "does not enqueue an e-mail message and raises an error" do
      expect { described_class.with(project_id:).project_creation.deliver }.to raise_error(ArgumentError, "Invalid Project ID provided for the TigerdataMailer: #{project_id}")
    end
  end

end

context "When a request is created" do
  it "Sends project creation requests" do
    expect { described_class.with(request_id:, submitter: sponsor_and_data_manager_user).request_creation.deliver }.to change { ActionMailer::Base.deliveries.count }.by(1)
    mail = ActionMailer::Base.deliveries.last

    expect(mail.subject).to eq "New Project Request Ready for Review"
    expect(mail.to).to eq ["test@example.com"]
    expect(mail.cc).to eq ["test_to@example.com"]
    expect(mail.from).to eq [sponsor_and_data_manager_user.email]

    html_body = mail.html_part.body.to_s
    expect(html_body).to have_content(valid_request.project_title)
    expect(html_body).to have_content(valid_request.description)
    expect(html_body).to have_content(valid_request.state)
    expect(html_body).to have_content(valid_request.data_sponsor)
    expect(html_body).to have_content(valid_request.data_manager)
    expect(html_body).to have_content(valid_request.departments)
    expect(html_body).to have_content(valid_request.user_roles)
    expect(html_body).to have_content(valid_request.quota)
    expect(html_body).to have_content("A new project request has been created and is ready for review. The request can be viewed in the TigerData web portal: #{request_url(valid_request)}")
  end

  context "when the request ID is invalid or nil" do
    let(:request_id) { "invalid" }

    it "does not enqueue an e-mail message and raises an error" do
      expect { described_class.with(request_id:, submitter: sponsor_and_data_manager_user).request_creation.deliver }.to raise_error(ArgumentError, "Invalid Request ID provided for the TigerdataMailer: #{request_id}")
    end
  end
end
end
