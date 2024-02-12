# frozen_string_literal: true
class Project < ApplicationRecord
  validates_with ProjectValidator
  has_many :provenance_events, dependent: :destroy

  # TODO: What are the valid statuses?
  PENDING_STATUS = "pending"

  delegate :to_json, to: :metadata_json

  def metadata
    (metadata_json || {}).with_indifferent_access
  end

  def metadata=(metadata)
    self.metadata_json = metadata
  end

  # TODO: Presumably we should display other statuses as well?
  def title
    trailer = if in_mediaflux?
                ""
              else
                " (#{::Project::PENDING_STATUS})"
              end
    metadata[:title] + trailer
  end

  def departments
    unsorted = metadata[:departments] || []
    unsorted.sort
  end

  def directory
    metadata[:directory]
  end

  def status
    metadata[:status]
  end

  def in_mediaflux?
    mediaflux_id.present?
  end

  def self.sponsored_projects(sponsor)
    Project.where("metadata_json->>'data_sponsor' = ?", sponsor)
  end

  def self.managed_projects(manager)
    Project.where("metadata_json->>'data_manager' = ?", manager)
  end

  def self.data_user_projects(user)
    # See https://scalegrid.io/blog/using-jsonb-in-postgresql-how-to-effectively-store-index-json-data-in-postgresql/
    # for information on the @> operator
    query_ro = '{"data_user_read_only":["' + user + '"]}'
    query_rw = '{"data_user_read_write":["' + user + '"]}'
    Project.where("(metadata_json @> ? :: jsonb) OR (metadata_json @> ? :: jsonb)", query_ro, query_rw)
  end

  def save_in_mediaflux(session_id:)
    if mediaflux_id.nil?
      self.mediaflux_id = ProjectMediaflux.create!(project: self, session_id: session_id)
      save!
      Rails.logger.debug "Project #{id} has been created in MediaFlux (asset id #{mediaflux_id})"
    else
      ProjectMediaflux.update(project: self, session_id: session_id)
      Rails.logger.debug "Project #{id} has been updated in MediaFlux (asset id #{mediaflux_id})"
    end
    mediaflux_id
  end

  def created_by_user
    User.find_by(uid: metadata[:created_by])
  end

  def to_xml
    ProjectMediaflux.xml_payload(project: self)
  end

  def asset_count(session_id:)
    accum_req = Mediaflux::Http::GetMetadataRequest.new(session_token: session_id, id: mediaflux_id)
    xml_metadata = accum_req.metadata
    xml_metadata[:total_file_count]
  end

  def file_list(session_id:, size: 10)
    return { files: [] } if mediaflux_id.nil?

    query_req = Mediaflux::Http::QueryRequest.new(session_token: session_id, collection: mediaflux_id, action: "get-values", deep_search: true)
    iterator_id = query_req.result

    iterator_req = Mediaflux::Http::IteratorRequest.new(session_token: session_id, iterator: iterator_id, action: "get-values", size: size)
    results = iterator_req.result

    # Destroy _after_ fetching the results from iterator_req
    Mediaflux::Http::IteratorDestroyRequest.new(session_token: session_id, iterator: iterator_id).resolve

    results
  end

  def file_list_to_file(session_id:, filename:)
    return { files: [] } if mediaflux_id.nil?

    action = "get-values"
    query_req = Mediaflux::Http::QueryRequest.new(session_token: session_id, collection: mediaflux_id, action: action, deep_search: true)
    iterator_id = query_req.result

    File.open(filename, "w") do |file|
      file.write(file_header(action: action))
      loop do
        iterator_req = Mediaflux::Http::IteratorRequest.new(session_token: session_id, iterator: iterator_id, action: action, size: 1000)
        iterator_resp = iterator_req.result
        lines = process_iterator_response(iterator_resp: iterator_resp, action: action)
        file.write(lines.join("\r\n") + "\r\n")
        break if iterator_resp[:complete]
      end
    end

    # Destroy _after_ fetching the results from iterator_req
    Mediaflux::Http::IteratorDestroyRequest.new(session_token: session_id, iterator: iterator_id).resolve
  end

  private

    def file_header(action:)
      if action == "get-name"
        "ID, NAME, COLLECTION?\r\n"
      else
        "ID, PATH, NAME, COLLECTION?, LAST_MODIFIED, SIZE\r\n"
      end
    end

    def process_iterator_response(iterator_resp:, action:)
      lines = []
      iterator_resp[:files].each do |asset|
        lines << if action == "get-name"
                   "#{asset.id}, #{asset.name}, #{asset.collection}"
                 else
                   "#{asset.id}, #{asset.path_only}, #{asset.name}, #{asset.collection}, #{asset.last_modified}, #{asset.size}"
                 end
      end
      lines
    end
end
