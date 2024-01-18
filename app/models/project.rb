# frozen_string_literal: true
class Project < ApplicationRecord
  validates_with ProjectValidator

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

  # We will eventually need something like this.
  #
  # def create_mediaflux(session_id:, xml_namespace: nil)
  #   asset_id = ProjectMediaflux.create!(project: self, session_id: session_id, xml_namespace: xml_namespace)
  #   if asset_id.present?
  #     Rails.logger.debug "Project #{id} has been saved to Mediaflux (asset id #{asset_id.to_i})"
  #     self.mediaflux_id = asset_id.to_i
  #     save!
  #   else
  #     raise "Error creating project in Mediaflux"
  #   end
  # end

  def update_mediaflux(session_id:)
    ProjectMediaflux.update(project: self, session_id: session_id)
    Rails.logger.debug "Project #{id} has been updated in MediaFlux (asset id #{mediaflux_id}"
  end

  def created_by_user
    User.find_by(uid: metadata[:created_by])
  end

  def to_xml
    ProjectMediaflux.xml_payload(project: self)
  end
end
