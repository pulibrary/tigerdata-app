# frozen_string_literal: true
require "rails_helper"

RSpec.describe TigerdataMailer, type: :mailer do
  let(:project) { FactoryBot.create :project, project_id: "abc123/def" }
  let(:project_id) { project.id }

  it "Sends project creation requests" do
    expect { described_class.with(project_id:).project_creation.deliver }.to change { ActionMailer::Base.deliveries.count }.by(1)
    mail = ActionMailer::Base.deliveries.last

    expect(mail.subject).to eq "New Project Request Ready for Review"
    expect(mail.to).to eq ["test@example.com"]
    expect(mail.cc).to eq ["test_to@example.com"]
    expect(mail.from).to eq ["no-reply@princeton.edu"]
    html_body = mail.html_part.body.to_s
    expect(html_body).to have_content(project.metadata_model.title)
    project.metadata.keys.each do |field|
      next if ["updated_on", "created_on", "created_by", "updated_by", "departments", "submission"].include?(field)
      # NOTE: These are not included for 0.6 schema project creation requests
      next if [
        "hpc",
        "data_use_agreement",
        "project_visibility",
        "resource_type",
        "globus_request",
        "smb_request",
        "provisional"
      ].include?(field)

      value = project.metadata[field]
      value = value.sort.join(", ") if value.is_a? Array
      # TODO: Uncomment when the fields are available in the tigerdata:project schema
      # if field == "storage_capacity"
      #   expect(html_body).to have_content(value[:size][:requested])
      #   expect(html_body).to have_content(value[:unit][:requested])
      # elsif field == "storage_performance_expectations"
      #   expect(html_body).to have_content(value[:requested])
      # else
      #   expect(html_body).to have_content(value)
      # end
    end
    expect(mail.attachments.count).to be_positive
    # testing the json response
    expect(mail.attachments.first.filename).to eq "abc123_def.json"
    parsed_body = JSON.parse(mail.attachments.first.body.raw_source)
    expect(parsed_body).to eq project.metadata
    expect(mail.attachments.first.mime_type).to eq "application/json"
    # testing the xml response
    expect(mail.attachments.second.filename).to eq "abc123_def.xml"
    expect(mail.attachments.second.body.raw_source).to eq project.to_xml.gsub("\n", "\r\n")
    expect(mail.attachments.second.mime_type).to eq "application/xml"
  end

  it "creates a provenance entry for the project creation" do

    expect { described_class.with(project_id:).project_creation.deliver }.to change { ActionMailer::Base.deliveries.count }.by(1)
    mail = ActionMailer::Base.deliveries.last

    project.reload
    expect(project.metadata_model.submission).to include("requested_by")
    expect(project.metadata_model.submission).to include("request_date_time")

    expect(mail.subject).to eq "New Project Request Ready for Review"
    expect(mail.to).to eq ["test@example.com"]
    expect(mail.cc).to eq ["test_to@example.com"]
    expect(mail.from).to eq ["no-reply@princeton.edu"]
    html_body = mail.html_part.body.to_s

    expect(html_body).not_to be_empty

    expect(html_body).to include("The following project request is ready for review:")
    expect(html_body).to include("Please log in to the Presentation Layer to view more details and approve the project.")
    expect(html_body).to include("Gratefully, the RDSS Team")
    expect(html_body).to include(project.to_xml)
  end

  context "when the project ID is invalid or nil" do
    let(:project_id) { "invalid" }

    it "does not enqueue an e-mail message and raises an error" do
      expect { described_class.with(project_id:).project_creation.deliver }.to raise_error(ArgumentError, "Invalid Project ID provided for the TigerdataMailer: #{project_id}")
    end
  end
end
