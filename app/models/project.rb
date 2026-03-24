# frozen_string_literal: true

# Project model representing a data project in the TigerData system.
# Handles project metadata, validation, Mediaflux integration, and project lifecycle.
class Project < ApplicationRecord

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

  # @param [ProjectMetadata] initial_metadata The initial metadata for the project
  # @param [User] user The user creating the project
  # @return [String, nil] The project ID (DOI) if successfully created, nil if invalid
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

  # @param [User] current_user The user attempting to activate the project
  # @return [void] Raises an error if not approved or title mismatch
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

  # @param [User, nil] user The user drafting the DOI (optional)
  # @return [void] Sets the project_id to a draft DOI
  def draft_doi(user: nil)
    puldatacite = PULDatacite.new
    self.metadata_model.project_id = puldatacite.draft_doi
  end

  # Ideally this method should return a ProjectMetadata object (like `metadata_model` does)
  # but we'll keep them both while we are refactoring the code so that we don't break
  # everything at once since `metadata` is used everywhere.
  # @return [HashWithIndifferentAccess] The metadata hash
  def metadata
    @metadata_hash = (metadata_json || {}).with_indifferent_access
  end

  # @return [ProjectMetadata] The metadata model object
  def metadata_model
    @metadata_model ||= ProjectMetadata.new_from_hash(self.metadata)
  end

  # @param [ProjectMetadata] new_metadata_model The new metadata model
  # @return [ProjectMetadata] Sets the metadata model
  def metadata_model=(new_metadata_model)
    @metadata_model = new_metadata_model
  end

  # @param [ProjectMetadata] metadata_model The metadata model to set
  # @return [void] Sets the metadata_json field
  def metadata=(metadata_model)
    # Convert our metadata to a hash so it can be saved on our JSONB field
    metadata_hash = JSON.parse(metadata_model.to_json)
    self.metadata_json = metadata_hash
  end

  # @return [String] The project title
  def title
    self.metadata_model.title
  end

  # @return [Array<String>] Sorted list of departments
  def departments
    unsorted = metadata_model.departments || []
    unsorted.sort
  end

  # @return [String] The project directory path
  def project_directory
    metadata_model.project_directory || ""
  end

  # @return [String] The short project directory path
  def project_directory_short
    project_directory
  end

  # @return [String] The project status
  def status
    metadata_model.status
  end

  # @return [Boolean] Whether the project is in Mediaflux
  def in_mediaflux?
    mediaflux_id.present?
  end

  # This method narrows the list down returned by `all_projects` to only those projects where the user has
  # been given a role (e.g. sponsor, manager, or data user.) For most users `all_projects` and `user_projects`
  # are identical, but for administrators the lists can be very different since they are not part of most
  # projects even though they have access to them in Mediaflux.
  # @param [User] user The user
  # @return [Array<Hash>] Projects where the user has a role
  def self.users_projects(user)
    all_projects(user).select do |project|
      project[:data_manager] == user.uid || project[:data_sponsor] == user.uid || project[:data_users].include?(user.uid)
    end
  end

  # Returns the projects that the current user has access in Mediaflux given their credentials
  # @param [User] user The user
  # @param [String] aql_query The AQL query for filtering projects
  # @return [Array<Hash>] List of projects accessible to the user
  def self.all_projects(user, aql_query = "xpath(tigerdata:project/ProjectID) has value")
    request = Mediaflux::ProjectListRequest.new(session_token: user.mediaflux_session, aql_query:)
    request.resolve
    if request.error?
      Rails.logger.error("Error fetching project list for user #{user&.uid}: #{request.response_error[:message]}")
      Honeybadger.notify("Error fetching project list for user #{user&.uid}: #{request.response_error[:message]}")
      []
    else
      request.results
    end
  end

  # @return [User, nil] The user who created the project
  def created_by_user
    User.find_by(uid: metadata_model.created_by)
  end

  # @return [String] XML representation of the <meta> element
  def mediaflux_meta_xml(user:)
    doc = ProjectMediaflux.document(project: self, user: user)
    doc.xpath("/response/reply/result/asset/meta").to_s
  end

  # @param [String] session_id The Mediaflux session ID
  # @return [Hash] The Mediaflux metadata
  def mediaflux_metadata(session_id:)
    @mediaflux_metadata ||= begin
      metadata_request = Mediaflux::AssetMetadataRequest.new(session_token: session_id, id: mediaflux_id)
      metadata_request.metadata
    end
    @mediaflux_metadata
  end

  # @param [String] session_id The Mediaflux session ID
  # @return [Integer] The total file count
  def asset_count(session_id:)
    values = mediaflux_metadata(session_id:)
    values.fetch(:total_file_count, 0)
  end

  # @return [String] The default storage unit
  def self.default_storage_unit
    "KB"
  end

  # @return [String] The default storage usage
  def self.default_storage_usage
    "0 #{default_storage_unit}"
  end

  # @param [String] session_id The Mediaflux session ID
  # @return [String] The storage usage
  def storage_usage(session_id:)
    values = mediaflux_metadata(session_id:)
    values.fetch(:quota_used, self.class.default_storage_usage) # if the storage is empty use the default
  end

  # @param [String] session_id The Mediaflux session ID
  # @return [Integer] The raw storage usage
  def storage_usage_raw(session_id:)
    values = mediaflux_metadata(session_id:)
    values.fetch(:quota_used_raw, 0) # if the storage raw is empty use zero
  end

  # @return [String] The default storage capacity
  def self.default_storage_capacity
    "0 GB"
  end

  # @param [String] session_id The Mediaflux session ID
  # @return [String] The storage capacity
  def storage_capacity(session_id:)
    values = mediaflux_metadata(session_id:)
    quota_value = values.fetch(:quota_allocation, '') #if quota does not exist, set value to an empty string
    if quota_value.blank?
      return self.class.default_storage_capacity
    else
      return quota_value
    end
  end

  # @param [String] session_id The Mediaflux session ID
  # @return [Integer] The raw storage capacity
  def storage_capacity_raw(session_id:)
    values = mediaflux_metadata(session_id:)
    quota_value = values.fetch(:quota_allocation_raw, 0) #if quota does not exist, set value to 0
    quota_value
  end

  # Fetches the first n files
  # @param [String] session_id The Mediaflux session ID
  # @param [Integer] size The number of files to fetch
  # @return [Hash] The file list
  def file_list(session_id:, size: 10)
    return { files: [] } if mediaflux_id.nil?

    query_req = Mediaflux::QueryRequest.new(session_token: session_id, collection: mediaflux_id, deep_search: true, aql_query: "type!='application/arc-asset-collection'")
    iterator_id = query_req.result

    iterator_req = Mediaflux::IteratorRequest.new(session_token: session_id, iterator: iterator_id, size: size)
    results = iterator_req.result

    # Destroy _after_ fetching the first set of results from iterator_req.
    # This call is required since it possible that we have read less assets than
    # what the collection has but we are done with the iterator.
    Mediaflux::IteratorDestroyRequest.new(session_token: session_id, iterator: iterator_id).resolve

    results
  end

  def directory_listing(session_id:, size: 10, collection_id: nil)
    return { files: [] } if mediaflux_id.nil?

    collection_id ||= mediaflux_id
    query_req = Mediaflux::QueryRequest.new(session_token: session_id, collection: collection_id, deep_search: false)

    # handel query errors by returning the error message in the response so it can be displayed to the user
    return { error: query_req.response_error[:message] } if query_req.error?

    iterator_id = query_req.result
    iterator_req = Mediaflux::IteratorRequest.new(session_token: session_id, iterator: iterator_id, size: size)
    results = iterator_req.result

    # Destroy _after_ fetching the first set of results from iterator_req.
    # This call is required since it possible that we have read less assets than
    # what the collection has but we are done with the iterator.
    Mediaflux::IteratorDestroyRequest.new(session_token: session_id, iterator: iterator_id).resolve
    results
  end

  # Creates the iterator for the file explorer
  # @param [String] session_id The Mediaflux session ID
  # @param [String] path_id The path ID for the collection
  # @return [String] The iterator ID
  def file_explorer_setup(session_id:, path_id:)
    query_req = Mediaflux::QueryRequest.new(session_token: session_id, collection: path_id, deep_search: false)
    iterator_id = query_req.result
    iterator_id
  end

  # Fetchs results from the iterator for the file explorer
  # @param [String] session_id The Mediaflux session ID
  # @param [String] iterator_id The iterator ID
  # @param [Integer] size The number of items to fetch
  # @return [Hash] The iteration results
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
  # @param [String] session_id The Mediaflux session ID
  # @param [String] filename The filename to save to
  # @return [void] Generates the file inventory
  def file_list_to_file(session_id:, filename:)
    file_inventory = ProjectFileInventory.new(project: self, session_id:, filename:)
    file_inventory.generate()
  end

  # @param [String] session_id The Mediaflux session ID
  # @return [Hash] The quota information
  def quota(session_id:)
    quota_req = Mediaflux::ProjectQuotaRequest.new(session_token: session_id, asset_id: self.mediaflux_id)
    quota_req.quota
  end

  private

    # @param [Hash] iterator_resp The iterator response
    # @return [Array<String>] List of file lines
    def files_from_iterator(iterator_resp)
      lines = []
      iterator_resp[:files].each do |asset|
        lines << "#{asset.id}, #{asset.path_only}, #{asset.name}, #{asset.collection}, #{asset.last_modified}, #{asset.size}"
      end
      lines
    end

    # @return [Pathname] The project directory pathname
    def project_directory_pathname
      # allow the directory to be modified by changes in the metadata_json
      @project_directory_pathname = nil if @original_directory.present? && @original_directory != metadata_model.project_directory

      @project_directory_pathname ||= begin
        @original_directory = metadata_model.project_directory
        Pathname.new(@original_directory)
      end
    end
end
