# frozen_string_literal: true
class ProjectDashboardPresenter
  include ActionView::Helpers::DateHelper

  def initialize(project_mf)
    @project_mf = project_mf
  end

  def title
    @project_mf[:title]
  end

  def data_sponsor
    @project_mf[:data_sponsor]
  end

  def data_manager
    @project_mf[:data_manager]
  end

  def mediaflux_id
    @project_mf[:mediaflux_id]
  end

  def project
    @project ||= Project.where(mediaflux_id: mediaflux_id).first
  end

  def id
    project.id
  end

  def status
    "approved"
  end

  def updated_at
    project.updated_at
  end

  def type
    "TODO"
  end

  def latest_file_list_time
    "No Downloads"
  end

  def last_activity
    "Not yet active"
  end

  def role(user)
    if data_sponsor == user.uid
      "Sponsor"
    elsif data_manager == user.uid
      "Data Manager"
    else
      "Data User"
    end
  end

  def quota_percentage(session_id:)
    0.50
  end

  def quota_usage(session_id:)
    "3 GB"
  end

  # Removes "about" (as in "about 1 month ago") from time_ago_in_words
  def remove_about(time_ago)
    time_ago.gsub("about ", "")
  end
end
