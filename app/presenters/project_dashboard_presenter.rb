# frozen_string_literal: true
class ProjectDashboardPresenter < ProjectShowPresenter
  include ActionView::Helpers::DateHelper

  delegate :to_model, :updated_at, to: :project

  delegate :data_sponsor, :data_manager, to: :project_metadata

  def type
    if storage_performance_expectations["approved"].nil?
      "Requested #{storage_performance_expectations['requested']}"
    else
      storage_performance_expectations["approved"]
    end
  end

  def latest_file_list_time
    requests = FileInventoryRequest.where(project_id: project.id).order(completion_time: :desc)
    if requests.empty?
      "No Downloads"
    elsif requests.first.completion_time
      "Prepared #{time_ago_in_words(requests.first.completion_time)} ago"
    else
      "Preparing now"
    end
  end

  def last_activity
    if project_metadata.updated_on.nil?
      "Not yet active"
    else
      "#{remove_about time_ago_in_words(project_metadata.updated_on)} ago"
    end
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

  # Removes "about" (as in "about 1 month ago") from time_ago_in_words
  def remove_about(time_ago)
    time_ago.gsub("about ", "")
  end
end
