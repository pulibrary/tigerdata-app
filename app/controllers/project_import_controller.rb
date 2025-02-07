# frozen_string_literal: true
class ProjectImportController < ApplicationController
  def run
    if current_user.eligible_sysadmin?
      ProjectImport.run_with_report(mediaflux_session: current_user.mediaflux_session)
    else
      flash[:alert] = I18n.t(:access_denied)
      redirect_to root_path
    end
  end
end
