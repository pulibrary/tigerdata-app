# frozen_string_literal: true
class TigerdataMailer < ApplicationMailer
  def project_creation
    config = Rails.application.config.tigerdata_mail[:project_creation]
    @project = params[:project]
    mail(to: config[:to_email], subject: "Project Creation Request", cc: config[:cc_email])
  end
end
