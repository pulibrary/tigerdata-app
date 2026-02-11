# frozen_string_literal: true
class InventoryRequestPresenter
  attr_reader :inventory_request

  delegate :request_details, :job_id, :completion_time, :expiration_date, to: :inventory_request

  def initialize(inventory_request)
    @inventory_request = inventory_request
  end

  def list_contents_url
    url_helpers.project_list_contents_path(inventory_request.project)
  end

  def partial_name
    if inventory_request.state == InventoryRequest::COMPLETED
      "download_item"
    elsif inventory_request.state == InventoryRequest::FAILED
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
    url_helpers.new_project_review_and_submit_path(inventory_request.id)
  end

  def delete_path
    url_helpers.new_project_review_and_submit_path(inventory_request.id)
  end

  private

    def url_helpers
      Rails.application.routes.url_helpers
    end

    def helpers
      ActionController::Base.helpers
    end
end
