# frozen_string_literal: true
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
  def self.all_projects(user)
    request = Mediaflux::ProjectListRequest.new(session_token: user.mediaflux_session, aql_query: "xpath(tigerdata:project/ProjectID) has value")
    request.results
  end

  def user_has_access?(user:)
    return true if user.eligible_sysadmin?
    metadata_model.data_sponsor == user.uid || metadata_model.data_manager == user.uid ||
    metadata_model.data_user_read_only.include?(user.uid) || metadata_model.data_user_read_write.include?(user.uid)
  end

  def created_by_user
    User.find_by(uid: metadata_model.created_by)
  end

  def to_xml
    ProjectShowPresenter.new(self).to_xml
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

  # Fetches the first n files
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

  # Fetches the entire file list to a file
  def file_list_to_file(session_id:, filename:)
    return { files: [] } if mediaflux_id.nil?

    query_req = Mediaflux::QueryRequest.new(session_token: session_id, collection: mediaflux_id, deep_search: true,  aql_query: "type!='application/arc-asset-collection'")
    iterator_id = query_req.result

    start_time = Time.zone.now
    prefix = "file_list_to_file #{session_id[0..7]} #{self.metadata_model.project_id}"
    log_elapsed(start_time, prefix, "STARTED")

    File.open(filename, "w") do |file|
      page_number = 0
      # file header
      file.write("ID, PATH, NAME, COLLECTION?, LAST_MODIFIED, SIZE\r\n")
      loop do
        iterator_start_time = Time.zone.now
        page_number += 1
        iterator_req = Mediaflux::IteratorRequest.new(session_token: session_id, iterator: iterator_id, size: 1000)
        iterator_resp = iterator_req.result
        log_elapsed(iterator_start_time, prefix, "FETCHED page #{page_number} from iterator")
        lines = files_from_iterator(iterator_resp)
        file.write(lines.join("\r\n") + "\r\n")
        break if iterator_resp[:complete] || iterator_req.error?
      end
      log_elapsed(start_time, prefix, "ENDED")
    end

    # Destroy _after_ fetching the results from iterator_req
    # This call is technically not necessary since Mediaflux automatically deletes the iterator
    # once we have ran through it and by now we have. But it does not hurt either.
    Mediaflux::IteratorDestroyRequest.new(session_token: session_id, iterator: iterator_id).resolve
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

    # Ensure that the project directory is a valid path
    def safe_directory(directory)
      Project.safe_directory(directory)
    end

    def log_elapsed(start_time, prefix, message)
      elapsed_time = Time.zone.now - start_time
      timing_info = "#{format('%.2f', elapsed_time)} s"
      Rails.logger.info "#{prefix}: #{message}, #{timing_info}"
    end
end
