# frozen_string_literal: true
class DashboardPresenter
  attr_reader :current_user
  def initialize(current_user:)
    @current_user = current_user
  end

  def all_projects
    return [] unless current_user&.eligible_sysadmin?
    # Since we are now fetching the projects from Mediaflux the projects
    # that the user has access to is controlled by Mediaflux and therefore
    # "all" projects is the same as the projects shown to the user in the
    # dashboard.
    dashboard_projects
  end

  def dashboard_projects
    @dashboard_projects ||= Project.users_projects(current_user)
                                   .map { |project| ProjectDashboardPresenter.new(project) }
                                   .select(&:project_in_rails?)
                                   .sort_by(&:updated_at)
                                   .reverse
    @dashboard_projects
  end

  def my_inventory_requests
    @my_inventory_requests ||= current_user.user_requests.where(type: "FileInventoryRequest")
  end

  def my_draft_requests
    @my_draft_requests ||= Request.where(requested_by: current_user.uid, state: Request::DRAFT)
  end

  def my_submitted_requests
    @my_submitted_requests ||= Request.where(requested_by: current_user.uid, state: Request::SUBMITTED)
  end
end
