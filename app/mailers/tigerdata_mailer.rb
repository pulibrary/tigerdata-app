# frozen_string_literal: true
class TigerdataMailer < ApplicationMailer
  def project_creation
    config = Rails.application.config.tigerdata_mail[:project_creation]
    @project_id = params[:project_id]
    raise(ArgumentError, "Invalid Project ID provided for the TigerdataMailer: #{@project_id}") if project.nil?

    admin_email = params[:approver].email || Rails.application.config.tigerdata_mail[:to_email]
    title = project.title
    subject = "Project: '#{title}' has been approved"
    mail(to: admin_email, cc: config[:cc_email], subject:)
  end

  def request_creation
    config = Rails.application.config.tigerdata_mail[:request_creation]
    @request_id = params[:request_id]
    submitter_mail = params[:submitter].email

    raise(ArgumentError, "Invalid Request ID provided for the TigerdataMailer: #{@request_id}") if request.nil?

    subject = "New Project Request Ready for Review"
    mail(to: config[:to_email], cc: config[:cc_email], from: submitter_mail, subject:)
  end
  private

    def request
      @request ||= Request.find_by(id: @request_id)
    end

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
