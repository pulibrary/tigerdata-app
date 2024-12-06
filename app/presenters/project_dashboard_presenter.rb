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

  def updated_at
    project.updated_at
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

  def quota_usage(session_id:)
    if project.pending?
      quota_usage = "0 KB out of 0 GB used"
    else
      quota_usage = "#{project.storage_usage(session_id:)} out of #{project.storage_capacity(session_id:)} used"
    end
    quota_usage
  end

  def quota_percentage(session_id:)
    q_percent = project.storage_capacity_raw(session_id:).zero? ? 0 : (project.storage_usage_raw(session_id:).to_f / project.storage_capacity_raw(session_id:).to_f) * 100

    if project.pending?
      0
    else
      q_percent
    end
  end
end
