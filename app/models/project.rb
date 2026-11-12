# frozen_string_literal: true

class Project < ApplicationRecord
  class MediafluxError < StandardError; end

  validates_with ProjectValidator
  has_many :provenance_events, dependent: :destroy

  # Valid project status described in ADR 7
  # See `architecture-decisions/0007-valid-project-statuses.md`
  APPROVED_STATUS = "approved"
  ACTIVE_STATUS = "active"

  delegate :to_json, to: :metadata_json # field in the database

  def in_mediaflux?
    mediaflux_id.present?
  end

  # This method narrows the list down returned by `all_projects` to only those projects where the user has
  # been given a role (e.g. sponsor, manager, or data user.) For most users `all_projects` and `user_projects`
  # are identical, but for administrators the lists can be very different since they are not part of most
  # projects even though they have access to them in Mediaflux.
  def self.users_projects(user)
    all_projects(user).select do |project|
      project[:data_manager] == user.uid || project[:data_sponsor] == user.uid || project[:data_users].include?(user.uid)
    end
  end

  # Returns the projects that the current user has access in Mediaflux given their credentials
  def self.all_projects(user, aql_query = "xpath(tigerdata:project/ProjectID) has value")
    ProjectList.new(user, aql_query).all_projects
  end

  # @return [String] XML representation of the <meta> element
  def mediaflux_meta_xml(user:)
    doc = ProjectMediaflux.document(project: self, user: user)
    doc.xpath("/response/reply/result/asset/meta").to_s
  end

  def mediaflux_metadata(session_id:)
    @mediaflux_metadata ||= begin
      metadata_request = Mediaflux::AssetMetadataRequest.new(session_token: session_id, id: mediaflux_id)
      metadata_request.metadata
    end
    @mediaflux_metadata
  end

  def asset_count(session_id:)
    values = mediaflux_metadata(session_id:)
    values.fetch(:total_file_count, 0)
  end

  def self.default_storage_unit
    "KB"
  end

  def self.default_storage_usage
    "0 #{default_storage_unit}"
  end

  def storage_usage(session_id:)
    values = mediaflux_metadata(session_id:)
    values.fetch(:quota_used, self.class.default_storage_usage) # if the storage is empty use the default
  end

  def storage_usage_raw(session_id:)
    values = mediaflux_metadata(session_id:)
    values.fetch(:quota_used_raw, 0) # if the storage raw is empty use zero
  end

  def self.default_quota_allocation
    "0 GB"
  end

  def quota_allocation(session_id:)
    values = mediaflux_metadata(session_id:)
    quota_value = values.fetch(:quota_allocation, '') # if quota does not exist, set value to an empty string
    if quota_value.blank?
      return self.class.default_quota_allocation
    else
      return quota_value
    end
  end

  def quota_allocation_raw(session_id:)
    values = mediaflux_metadata(session_id:)
    quota_value = values.fetch(:quota_allocation_raw, 0) # if quota does not exist, set value to 0
    quota_value
  end

  # Build a query request for the project with the given arguments. This method is used to handle errors that may occur when building the query request and to log them properly.
  # @param query_request_args [Hash] the arguments to build the query request, should include at least the session_token and collection (mediaflux_id) keys
  # @raise [MediafluxError] if there is an error with the query request, the error message will be included in the exception message
  #
  # @return [Mediaflux::QueryRequest] the query request object for the project, which can be used to fetch the iterator and results
  def build_query_request(**query_request_args)
    query_req = Mediaflux::QueryRequest.new(**query_request_args)
    # handle query errors by returning the error message in the response so it can be displayed to the user
    if query_req.error?
      response_error = query_req.response_error
      error_message = response_error[:message]
      Rails.logger.error("Error fetching iterator for collection #{query_request_args[:collection]} with argument keys #{query_request_args.keys}: #{error_message}")
      raise MediafluxError.new(error_message)
    end

    query_req
  end

  # @param iterator_id [String] the id of the iterator to fetch results from
  # @param session_id [String] mediaflux session id to use for the query
  # @param size [Integer] number of files to fetch, defaults to 10
  #
  # @return [Hash] a hash with the files or an empty array if there are no files or the project is not in mediaflux
  def resolve_iterator_request(iterator_id:, session_id:, size: 10)
    iterator_req = Mediaflux::IteratorRequest.new(session_token: session_id, iterator: iterator_id, size: size)
    response = iterator_req.result

    # Destroy _after_ fetching the first set of results from iterator_req.
    # This call is required since it possible that we have read less assets than
    # what the collection has but we are done with the iterator.
    destroy_request = Mediaflux::IteratorDestroyRequest.new(session_token: session_id, iterator: iterator_id)
    destroy_request.resolve

    response
  end

  # Fetches the first n files in the project directory
  # @param session_id [String] mediaflux session id to use for the query
  # @param size [Integer] number of files to fetch, defaults to 10
  # @param collection_id [String] optional collection id to fetch from, defaults to the project collection
  #
  # @return [Hash] a hash with either the files or an error message if the query failed
  def directory_listing(session_id:, size: 10, collection_id: nil)
    listing = { files: [] }
    return listing if mediaflux_id.nil?

    collection_id ||= mediaflux_id
    query_request_args = {
      session_token: session_id,
      collection: collection_id,
      deep_search: false,
    }
    begin
      query_request = build_query_request(**query_request_args)
    rescue MediafluxError => e
      listing = { error: e.message }
      return listing
    rescue StandardError => e
      raise e
    end

    iterator_id = query_request.result
    results = resolve_iterator_request(iterator_id: iterator_id, session_id: session_id, size: size)
  end

  # Fetches the entire file list to a file
  def file_list_to_file(session_id:, filename:)
    file_inventory = ProjectFileInventory.new(project: self, session_id:, filename:)
    file_inventory.generate()
  end

  def quota(session_id:)
    quota_req = Mediaflux::ProjectQuotaRequest.new(session_token: session_id, asset_id: self.mediaflux_id)
    quota_req.quota
  end

  # Fetch the live Mediaflux quota, persist it on metadata_json, and return the quota hash.
  def refresh_storage_capacity_from_mediaflux!(session_id:)
    raise MediafluxError, "Project #{id} has no Mediaflux id; cannot refresh quota" if mediaflux_id.blank?

    quota_info = quota(session_id:)
    human = quota_info[:quota_allocation_human]
    size, unit = parse_human_quota(human)
    project_metadata = ProjectMetadata.new(self)
    project_metadata.apply_approved_quota(size:, unit:)
    project_metadata.update_project
    quota_info
  end

  private

  def parse_human_quota(human)
    match = human.to_s.strip.match(/\A([\d.]+)\s+([A-Za-z]+)\z/)
    if match.nil?
      raise MediafluxError, "Unable to parse Mediaflux quota allocation #{human.inspect} for project #{id}"
    end

    number = BigDecimal(match[1])
    size = number.frac.zero? ? number.to_i : number.to_f
    [size, match[2]]
  end

  def files_from_iterator(iterator_resp)
    lines = []
    iterator_resp[:files].each do |asset|
      lines << "#{asset.id}, #{asset.path_only}, #{asset.name}, #{asset.collection}, #{asset.last_modified}, #{asset.size}"
    end
    lines
  end
end
