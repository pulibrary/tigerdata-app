# frozen_string_literal: true
class TigerdataMailer < ApplicationMailer
  def project_creation
    config = Rails.application.config.tigerdata_mail[:project_creation]
    @project = params[:project]

    filebase = @project.metadata[:project_id].tr("/", "_")

    # attaching json response  to the mailer
    json_content = @project.to_json
    attachments["#{filebase}.json"] = {
      mime_type: "application/json",
      content: json_content
    }

    # attaching xml response to the mailer
    xml_content = @project.to_xml
    attachments["#{filebase}.xml"] = {
      mime_type: "application/xml",
      content: xml_content
    }

    mail(to: config[:to_email], subject: "Project Creation Request", cc: config[:cc_email])
  end
end
