# frozen_string_literal: true
require "rails_helper"

RSpec.describe TigerdataMailer, type: :mailer do
  let(:project) { FactoryBot.create :project, project_id: "abc123/def" }

  it "Sends project creation reuests" do
    expect { described_class.with(project: project).project_creation.deliver }.to change { ActionMailer::Base.deliveries.count }.by(1)
    mail = ActionMailer::Base.deliveries.last

    expect(mail.subject).to eq "Project Creation Request"
    expect(mail.to).to eq ["test@example.com"]
    expect(mail.cc).to eq ["test_to@example.com"]
    expect(mail.from).to eq ["no-reply@princeton.edu"]
    html_body = mail.html_part.body.to_s
    expect(html_body).to have_content(project.metadata[:title])
    project.metadata.keys.each do |field|
      next if ["updated_on", "created_on", "created_by", "updated_by"].include?(field)
      value = project.metadata[field]
      value = value.sort.join(", ") if value.is_a? Array
      expect(html_body).to have_content(value)
    end
    expect(mail.attachments.count).to be_positive
    # testing the json response
    expect(mail.attachments.first.filename).to eq "abc123_def.json"
    expect(mail.attachments.first.body.raw_source).to eq project.metadata.to_json
    expect(mail.attachments.first.mime_type).to eq "application/json"
    # testing the xml response
    expect(mail.attachments.second.filename).to eq "abc123_def.xml"
    expect(mail.attachments.second.body.raw_source).to eq project.to_xml.gsub("\n", "\r\n")
    expect(mail.attachments.second.mime_type).to eq "application/xml"
  end
end
