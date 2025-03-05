# frozen_string_literal: true
class ProjectImportController < ApplicationController
  def run
    if current_user.eligible_sysadmin?
      @results = ProjectImport.run_with_report(mediaflux_session: current_user.mediaflux_session).sort
      created_count = @results.count { |out| out.starts_with?("Created") }
      notice = "Created #{created_count} #{'project'.pluralize(created_count)}."
      flash[:notice] = notice
    else
      flash[:alert] = I18n.t(:access_denied)
      redirect_to dashboard_path
    end
  end
end
