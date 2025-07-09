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
  PENDING_STATUS = "pending"
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

  def approve!(current_user:)
    if self.metadata_model.project_directory.include?("tigerdata/") == false
      self.metadata_model.project_directory = "tigerdata/#{self.metadata_model.project_directory}"
    end
    puts self.metadata_model.project_directory
    byebug

    request = Mediaflux::ProjectCreateServiceRequest.new(session_token: current_user.mediaflux_session, project: self)
    request.resolve

    self.mediaflux_id = request.mediaflux_id
    self.metadata_model.status = Project::APPROVED_STATUS
    self.save!

    # create two provenance events:
    # - one for approving the project and
    # - another for changing the status of the project
    # - another with debug information from the create project service
    ProvenanceEvent.generate_approval_events(project: self, user: current_user, debug_output: request.debug_output)
  end

  def reload
    super
    @metadata_model = ProjectMetadata.new_from_hash(self.metadata)
    self
  end

  def activate!(collection_id:, current_user:)
    response = Mediaflux::AssetMetadataRequest.new(session_token: current_user.mediaflux_session, id: collection_id)
    mediaflux_metadata = response.metadata # get the metadata of the collection from mediaflux

    return unless mediaflux_metadata[:collection] == true # If the collection id exists

    # check if the project doi in rails matches the project doi in mediaflux
    return unless mediaflux_metadata[:project_id] == self.metadata_model.project_id

    # activate a project by setting the status to 'active'
    self.metadata_model.status = Project::ACTIVE_STATUS

    # also read in the actual project directory
    self.metadata_model.project_directory = mediaflux_metadata[:project_directory]
    self.save!

    ProvenanceEvent.generate_active_events(project: self, user: current_user)
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

  def project_directory_parent_path
    Mediaflux::Connection.root
  end

  def project_directory_short
    project_directory
  end

  def status
    metadata_model.status
  end

  def pending?
    status == PENDING_STATUS
  end

  def in_mediaflux?
    mediaflux_id.present?
  end

  def self.users_projects(user)
    # See https://scalegrid.io/blog/using-jsonb-in-postgresql-how-to-effectively-store-index-json-data-in-postgresql/
    # for information on the @> operator
    uid = user.uid
    query_ro = '{"data_user_read_only":["' + uid + '"]}'
    query_rw = '{"data_user_read_write":["' + uid + '"]}'
    query = "(metadata_json @> ? :: jsonb) OR (metadata_json @> ? :: jsonb)"
    args = [query_ro, query_rw]
    if user.eligible_sponsor?
      query += "OR (metadata_json->>'data_sponsor' = ?)"
      args << uid
    end
    if user.eligible_manager?
      query += "OR (metadata_json->>'data_manager' = ?)"
      args << uid
    end
    Project.where( query, *args)
  end

  def self.sponsored_projects(sponsor)
    Project.where("metadata_json->>'data_sponsor' = ?", sponsor)
  end

  def self.managed_projects(manager)
    Project.where("metadata_json->>'data_manager' = ?", manager)
  end

  def self.pending_projects
    Project.where("mediaflux_id IS NULL")
  end

  def self.approved_projects
    Project.where("mediaflux_id IS NOT NULL")
  end

  def self.data_user_projects(user)
    # See https://scalegrid.io/blog/using-jsonb-in-postgresql-how-to-effectively-store-index-json-data-in-postgresql/
    # for information on the @> operator
    query_ro = '{"data_user_read_only":["' + user + '"]}'
    query_rw = '{"data_user_read_write":["' + user + '"]}'
    Project.where("(metadata_json @> ? :: jsonb) OR (metadata_json @> ? :: jsonb)", query_ro, query_rw)
  end

  def user_has_access?(user:)
    return true if user.eligible_sysadmin?
    metadata_model.data_sponsor == user.uid || metadata_model.data_manager == user.uid ||
    metadata_model.data_user_read_only.include?(user.uid) || metadata_model.data_user_read_write.include?(user.uid)
  end

  def save_in_mediaflux(user:)
    ProjectMediaflux.save(project: self, user: user)
  end

  def created_by_user
    User.find_by(uid: metadata_model.created_by)
  end

  def to_xml
    ProjectMediaflux.xml_payload(project: self)
  end

  # @return [Nokogiri::XML::Document] the Mediaflux XML document for this project
  def mediaflux_document
    ProjectMediaflux.document(project: self)
  end

  # @return [Nokogiri::XML::Element] the <meta> element from the Mediaflux XML document
  def mediaflux_meta_element
    doc = mediaflux_document.clone
    # Remove the namespaces in order to simplify the XPath query
    doc.remove_namespaces!
    elements = doc.xpath("/request/service/args/meta")
    raise("Failed to extract the <meta> element found in the Mediaflux XML document for project #{self.id}") if elements.empty?

    elements.first
  end

  # @return [String] XML representation of the <meta> element
  def mediaflux_meta_xml
    mediaflux_meta_element.to_xml
  end

  def mediaflux_metadata(session_id:)
    @mediaflux_metadata ||= begin
      accum_req = Mediaflux::AssetMetadataRequest.new(session_token: session_id, id: mediaflux_id)
      accum_req.metadata
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

  # Ensure that the project directory is a valid path
  # @example
  #   Project.safe_directory("My Project") # => "My-Project"
  def self.safe_directory(directory)
    # only alphanumeric characters and /
    name.strip.gsub(/[^A-Za-z\d\/]/, "-")
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
