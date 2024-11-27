# frozen_string_literal: true
class ProjectDashboardPresenter < ProjectShowPresenter
  include ActionView::Helpers::DateHelper

  delegate :to_model, to: :project

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
    else
      "Prepared #{time_ago_in_words(requests.first.completion_time)} ago"
    end
  end

  def last_activity
    if project_metadata.updated_on.nil?
      "Not yet active"
    else
      "#{time_ago_in_words(project_metadata.updated_on)} ago"
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

  def storage_usage(session_id:)
    storage_usage = "#{project.storage_usage(session_id:)} out of"
    storage_usage
  end

  def storage_capacity(session_id:)
    storage_capacity = project.storage_capacity(session_id:)
    storage_capacity
  end
end
