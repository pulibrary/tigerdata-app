# frozen_string_literal: true
class ProjectDashboardPresenter
  include ActionView::Helpers::DateHelper

  def initialize(project)
    @project = project
  end

  def title
    @project[:title]
  end

  def data_sponsor
    @project[:data_sponsor]
  end

  def data_manager
    @project[:data_manager]
  end

  def id
    "123"
  end

  def status
    "approved"
  end

  def updated_at
    "TODO"
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
