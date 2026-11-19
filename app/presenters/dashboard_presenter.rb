# frozen_string_literal: true

class DashboardPresenter
  attr_reader :current_user, :display_modal, :all_unfiltered_projects

  def initialize(current_user:, all_unfiltered_projects:, display_modal: "")
    @current_user = current_user
    @display_modal = display_modal
    @all_unfiltered_projects = all_unfiltered_projects
  end

  def all_projects
    # Short-cut to prevent an extra call to Mediaflux for non-admins
    # which are the large majority of our users.
    return [] unless current_user&.eligible_sysadmin?

    @all_projects ||= all_unfiltered_projects
                      .map { |project| ProjectDashboardPresenter.new(project, current_user) }
                      .reject { |presenter| presenter.project_metadata.nil? }
                      .sort_by(&:updated_at)
                      .reverse
    @all_projects
  end

  def dashboard_projects
    @dashboard_projects ||= user_projects.map { |project| ProjectDashboardPresenter.new(project, current_user) }
                                         .reject { |presenter| presenter.project_metadata.nil? }
                                         .sort_by(&:updated_at)
                                         .reverse
    @dashboard_projects
  end

  def my_inventory_requests
    @my_inventory_requests ||= current_user.inventory_requests.where(type: "FileInventoryRequest")
  end

  def my_draft_requests
    @my_draft_requests ||= presented_requests(NewProjectRequest.where(requested_by: current_user.uid, state: NewProjectRequest::DRAFT))
  end

  def my_submitted_requests
    @my_submitted_requests ||= presented_requests(NewProjectRequest.where(requested_by: current_user.uid, state: NewProjectRequest::SUBMITTED))
  end

  def requests_to_approve
    @requests_to_approve ||= if current_user.eligible_sysadmin?
                               presented_requests(NewProjectRequest.where(state: NewProjectRequest::SUBMITTED).order(created_at: :desc))
                             else
                               []
                             end
  end

  def display_confirm_delete_draft_modal?
    display_modal == "confirm_delete_draft"
  end

  private

  def presented_requests(requests)
    requests.map { |req| NewProjectRequestPresenter.new(req) }
  end

  # This method narrows the list down returned by `all_projects` to only those projects where the user has
  # been given a role (e.g. sponsor, manager, or data user.) For most users `all_projects` and `user_projects`
  # are identical, but for administrators the lists can be very different since they are not part of most
  # projects even though they have access to them in Mediaflux.
  def user_projects
    @user_projects ||= all_unfiltered_projects.select do |project|
      project[:data_manager] == current_user.uid || project[:data_sponsor] == current_user.uid || project[:data_users].include?(current_user.uid)
    end
  end
end
