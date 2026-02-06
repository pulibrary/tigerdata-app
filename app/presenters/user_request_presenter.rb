# frozen_string_literal: true
class UserRequestPresenter
  attr_reader :user_request

  delegate :request_details, :job_id, :completion_time, :expiration_date, to: :user_request

  def initialize(user_request)
    @user_request = user_request
  end

  def list_contents_url
    url_helpers.project_list_contents_path(user_request.project)
  end

  def partial_name
    if user_request.state == InventoryRequest::COMPLETED
      "download_item"
    elsif user_request.state == InventoryRequest::FAILED
      "failed_item"
    end
  end

  def title
    request_details["project_title"]
  end

  def download_link
    helpers.link_to(title, url_helpers.project_file_list_download_path(job_id: job_id))
  end

  def expiration
    "Expires in #{helpers.time_ago_in_words(expiration_date)}"
  end

  def size
    helpers.number_to_human_size(request_details["file_size"])
  end

  def review_path
    url_helpers.new_project_review_and_submit_path(user_request.id)
  end

  def delete_path
    url_helpers.new_project_review_and_submit_path(user_request.id)
  end

  private

    def url_helpers
      Rails.application.routes.url_helpers
    end

    def helpers
      ActionController::Base.helpers
    end
end
