# frozen_string_literal: true
class ProjectImportController < ApplicationController
  def run
    if current_user.eligible_sysadmin?
      output = ProjectImport.run_with_report(mediaflux_session: current_user.mediaflux_session)
      created_count = output.count { |out| out.starts_with?("Created") }
      error_output = output.reject { |out| out.starts_with?("Created") }
      notice = "Created #{created_count} #{'project'.pluralize(created_count)}."
      notice += " The following errors occurred: <ul><li>#{error_output.join('</li><li>')}</li><ul>" if error_output.count > 0
      flash[:notice] = notice
    else
      flash[:alert] = I18n.t(:access_denied)
    end
    redirect_to dashboard_path
  end
end
