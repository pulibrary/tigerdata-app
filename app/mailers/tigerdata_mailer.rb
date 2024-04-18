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
    @xml_content = project.to_xml

    data_sponsor = project_metadata[:data_sponsor]
    created_on = project_metadata[:created_on]
    submission_provenance = {
      # "RequestedBy": data_sponsor,
      "requested_by": data_sponsor,
      # "RequestDateTime": created_on
      "request_date_time": created_on
    }

    updated = project_metadata.dup # This is needed to ensure that the Hash is mutable for the Project Model
    updated[:submission] = submission_provenance
    project.metadata = updated
    project.save

    attachments["#{filebase}.xml"] = {
      mime_type: "application/xml",
      content: @xml_content
    }

    subject = "New Project Request Ready for Review"
    mail(to: config[:to_email], cc: config[:cc_email], subject:)
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
