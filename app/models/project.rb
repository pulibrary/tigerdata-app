# frozen_string_literal: true
class Project < ApplicationRecord
  class MediafluxError < StandardError; end

  validates_with ProjectValidator
  has_many :provenance_events, dependent: :destroy
  before_save do |project|
    # Ensure that the metadata JSONB postgres field is persisted properly
    project.metadata = project.metadata_model
  end

  # Valid project status described in ADR 7
  # See `architecture-decisions/0007-valid-project-statuses.md`
  APPROVED_STATUS = "approved"
  ACTIVE_STATUS = "active"

  delegate :to_json, to: :metadata_json # field in the database

  def create!(initial_metadata:, user:)
    self.metadata_model = initial_metadata
    if self.valid?
      if initial_metadata.project_id == ProjectMetadata::DOI_NOT_MINTED
        self.draft_doi(user: user)
        self.save!
        ProvenanceEvent.generate_submission_events(project: self, user: user)
      else
        self.save!
      end
      # return doi
      self.metadata_model.project_id
    else
      nil
    end
  end

  def activate(current_user:)
    raise StandardError.new("Only approved projects can be activated") if self.status != Project::APPROVED_STATUS
    metadata_request = Mediaflux::AssetMetadataRequest.new(session_token: current_user.mediaflux_session, id: self.mediaflux_id)
    metadata_request.resolve
    raise metadata_request.response_error if metadata_request.error?
    if self.title == metadata_request.metadata[:title]
      self.metadata_model.status = Project::ACTIVE_STATUS
      self.save!
    else
      raise StandardError.new("Title mismatch: #{self.title} != #{metadata_request.metadata[:title]}")
    end
  end

  def draft_doi(user: nil)
    puldatacite = PULDatacite.new
    self.metadata_model.project_id = puldatacite.draft_doi
  end

  # Ideally this method should return a ProjectMetadata object (like `metadata_model` does)
  # but we'll keep them both while we are refactoring the code so that we don't break
  # everything at once since `metadata` is used everywhere.
  def metadata
    @metadata_hash = (metadata_json || {}).with_indifferent_access
  end

  def metadata_model
    @metadata_model ||= ProjectMetadata.new_from_hash(self.metadata)
  end

  def metadata_model=(new_metadata_model)
    @metadata_model = new_metadata_model
  end

  def metadata=(metadata_model)
    # Convert our metadata to a hash so it can be saved on our JSONB field
    metadata_hash = JSON.parse(metadata_model.to_json)
    self.metadata_json = metadata_hash
  end

  def title
    self.metadata_model.title
  end

  def departments
    unsorted = metadata_model.departments || []
    unsorted.sort
  end

  def project_directory
    metadata_model.project_directory || ""
  end

  def project_directory_short
    project_directory
  end

  def status
    metadata_model.status
  end

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

  def created_by_user
    User.find_by(uid: metadata_model.created_by)
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

  def self.default_storage_capacity
    "0 GB"
  end

  def storage_capacity(session_id:)
    values = mediaflux_metadata(session_id:)
    quota_value = values.fetch(:quota_allocation, '') #if quota does not exist, set value to an empty string
    if quota_value.blank?
      return self.class.default_storage_capacity
    else
      return quota_value
    end
  end

  def storage_capacity_raw(session_id:)
    values = mediaflux_metadata(session_id:)
    quota_value = values.fetch(:quota_allocation_raw, 0) #if quota does not exist, set value to 0
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

  # Fetches the first n files (excludes arc-asset-collection Mediaflux resources)
  # @param session_id [String] mediaflux session id to use for the query
  # @param size [Integer] number of files to fetch, defaults to 10
  #
  # @return [Hash] a hash with the files or an empty array if there are no files or the project is not in mediaflux
  def file_list(session_id:, size: 10)
    listing = { files: [] }
    return listing if mediaflux_id.nil?

    aql_query = "type!='application/arc-asset-collection'"
    query_request_args = {
      session_token: session_id,
      collection: mediaflux_id,
      deep_search: true,
      aql_query: aql_query
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

    results
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

  # Creates the iterator for the file explorer
  def file_explorer_setup(session_id:, path_id:)
    query_req = Mediaflux::QueryRequest.new(session_token: session_id, collection: path_id, deep_search: false)
    iterator_id = query_req.result
    iterator_id
  end

  # Fetchs results from the iterator for the file explorer
  def file_explorer_iterate(session_id:, iterator_id:, size: 20)
    iterator_req = Mediaflux::IteratorRequest.new(session_token: session_id, iterator: iterator_id, size: size)
    results = iterator_req.result

    if iterator_req.error?
      results[:error] = true
    else
      results[:error] = false
      # Strip the beginning "/princeton" from the path
      results[:files].each do |file|
        file.path = file.path.gsub(/^\/princeton/,"")
      end
    end
    results
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

  private

    def files_from_iterator(iterator_resp)
      lines = []
      iterator_resp[:files].each do |asset|
        lines << "#{asset.id}, #{asset.path_only}, #{asset.name}, #{asset.collection}, #{asset.last_modified}, #{asset.size}"
      end
      lines
    end

    def project_directory_pathname
      # allow the directory to be modified by changes in the metadata_json
      @project_directory_pathname = nil if @original_directory.present? && @original_directory != metadata_model.project_directory

      @project_directory_pathname ||= begin
        @original_directory = metadata_model.project_directory
        Pathname.new(@original_directory)
      end
    end
end
