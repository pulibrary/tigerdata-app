# frozen_string_literal: true
class TigerdataMailer < ApplicationMailer
  def project_creation
    config = Rails.application.config.tigerdata_mail[:project_creation]
    @project_id = params[:project_id]

    raise(ArgumentError, "Invalid Project ID provided for the TigerdataMailer: #{@project_id}") if project.nil?

    # attaching json response  to the mailer
    json_content = project_metadata.to_json
    attachments["#{filebase}.json"] = {
      mime_type: "application/json",
      content: json_content
    }

    # attaching xml response to the mailer
    @xml_content = project.to_xml.html_safe

    attachments["#{filebase}.xml"] = {
      mime_type: "application/xml",
      content: @xml_content
    }

    subject = "New Project Request Ready for Review"
    mail(to: config[:to_email], cc: config[:cc_email], subject:)
  end

  def project_activation
    config = Rails.application.config.tigerdata_mail[:project_activation]
    @project_id = params[:project_id]
    raise(ArgumentError, "Invalid Project ID provided for the TigerdataMailer: #{@project_id}") if project.nil?

    @user_email = params[:user].email
    @message_body = params[:activation_failure_msg]

    subject = "Project Failed to Activate"
    mail(to: user_email, cc: config[:cc_email], subject:, template_name: 'activate')
  end

  private

    def project
      @project ||= Project.find_by(id: @project_id)
    end

    def project_metadata
      return if project.nil?

      project.metadata
    end

    def project_metadata_id
      return if project.nil?

      project_metadata[:project_id]
    end

    def filebase
      @filebase ||= project_metadata_id.tr("/", "_")
    end
end
