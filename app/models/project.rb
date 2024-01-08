# frozen_string_literal: true
class Project < ApplicationRecord
  validates_with ProjectValidator

  def metadata
    (metadata_json || {}).with_indifferent_access
  end

  def metadata=(metadata)
    self.metadata_json = metadata
  end

  def title
    trailer = if approved?
                ""
              else
                " (pending)"
              end
    metadata[:title] + trailer
  end

  def departments
    metadata[:departments] || []
  end

  def directory
    metadata[:directory]
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

  def approved?
    metadata["project_id"].present?
  end

  def approve!
    metadata = ProjectMetadata.new(current_user: nil, project: self)
    metadata.approve
  end

  def created_by_user
    User.find_by(uid: metadata[:created_by])
  end
end
